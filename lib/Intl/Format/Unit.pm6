unit module Unit;

use Intl::CLDR;
use Intl::UserLanguage;
use Intl::Number::Plural;
use Intl::Format::Number;

sub format-unit (
    $quantity,                  #= The number of units to format
    :$unit!,                    #= The unit used for formatting
    :$language = user-language, #= The language to format to
    :$length   = 'short',       #= The length (long, short, narrow)
    :$case     = 'nominative'   #= The case (nominative, accusative, etc).
) is export {

    my $number  = format-number $quantity, :$language;
    my $count   = plural-count  $quantity, :$language;
    my $pattern = cldr{$language}.units.simple{$unit}{$length}{$case}{$count}.pattern;

    $pattern.subst: '{0}', $number;
}


grammar UnitGrammar is export {
    # All tokens are delimited by '-' so we can use rules :-)
    token TOP       { <mixed> | <core> }
    token core      { <product>+  % '-per-' | 'per-' <product> }
    token mixed     { [<single>|<private>]+ % '-and-' }
    token product   { <single>+ % '-' ['-' <private>+ % '-']? }
    token single    { [<dimension> '-']? <prefixed> }
    token private   { ['xxx'|'x'] '-' <single> }
    token dimension { 'square' | 'cubic' | 'pow'[<[2..9]> |1<[0..5]> ] }
    token prefixed  { <prefix>? <simple> }
    # Per TR 35, prefixes come from
    # https://www.nist.gov/pml/special-publication-811/nist-guide-si-appendix-d-bibliography#05
    token prefix    {
        |                 exbi  | pebi  | tebi | gibi | mebi  | kibi |
        | yotta | zetta | exa   | peta  | tera | giga | mega  | kilo | hecto | deka
        | deci  | centi | milli | micro | nano | pico | femto | atto | zepto | yocto
    }
    token simple    { <unit-comp>+ % '-' | em | g | us | hg | of }
    # The unit can be anything, but obviously CLDR will limit itself to only the most common
    # (and quite a few not-so-common)
    token unit      { <[a..z]> ** 3..* }
}

role Fmt::Element {
    method format     { ... }
    method format-per { ... }
}
class Fmt::Per {
    has Str          $.orig;
    has Fmt::Element $!left  is built; # generally, fmt::product
    has Fmt::Element $!right is built; # generally, fmt::product
    method format (\units, \length, \case, \count) {
        # See if there is a unit format already
        .return with units.simple{$!orig}{length}{case}{count}.pattern;

        # If not, see if there's a 'per' for the right side
        return $!right.format-per.subst: '{0}', $!left.format;

        # # Finally, default to using plain old 'per'
        #my $per = units.compound.per{length}{case}{count}.pattern;
        #$per.subst:
        #    / '{' (<[01]>) '}' /,
        #    { $0 eq '0' ?? $!left.format !! $!right.format },
        #    :g
    }
    method format-per { die "This has been reached mistakenly" }
}
class Fmt::Times {
    has Str          $.orig;
    has Fmt::Element $!left  is built; # generally, fmt::dimensioned
    has Fmt::Element $!right is built; # generally, fmt::dimensioned
    method format (\units, \length, \case, \count) {
        # See if there is a unit format already
        .return with units.simple{$!orig}{length}{case}{count}.pattern;

        # If not, check if there is a
        return .subst: '{0}', $!left.format
        with units.simple{$!right.orig}{length}.per-unit;

        # Finally, default to using plain old 'per'
        my $per = units.compound.per{length}{case}{count}.pattern;
        $per.subst:
            / '{' (<[01]>) '}' /,
            { $0 eq '0' ?? $!left.format !! $!right.format },
            :g
    }
}


class FormatActions is export {
    method TOP { }
}
