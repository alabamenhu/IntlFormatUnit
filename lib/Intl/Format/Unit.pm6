unit module Unit;

use Intl::CLDR;
use Intl::UserLanguage;
use Intl::Number::Plural;
use Intl::Format::Number;

grammar UnitGrammar   {...}
grammar FormatActions {...}
sub get-unit-pattern  {...}

sub format-unit (
    $quantity,                  #= The number of units to format
    :$unit!,                    #= The unit used for formatting
    :$language = user-language, #= The language to format to
    :$length   = 'short',       #= The length (long, short, narrow)
    :$case     = 'nominative'   #= The case (nominative, accusative, etc).
) is export {

    my $number  = format-number $quantity, :$language;
    my $count   = plural-count  $quantity, :$language;
    my $pattern = get-unit-pattern $unit, $language, $length, $case, $count;
        UnitGrammar.parse($unit, :actions(Unit::FormatActions)).made;

    $pattern.subst: '{0}', $number;
}

sub get-unit-pattern ($unit, $language, $length, $case, $count) {
    state %cache;
    .return with %cache{"$unit $language $length $case $count"};

    my $formatter = UnitGrammar.parse($unit, :actions(Unit::FormatActions)).made;
    my $pattern = $formatter.format: cldr{$language}, $length, $case, $count;

    %cache{"$unit $language $length $case $count"} =
        $pattern.index('{0}') === Nil ?? "\{0\} $pattern" !! $pattern;
}


grammar UnitGrammar {
    # All tokens are delimited by '-' so we can use rules :-)
    token TOP        { <core> || <mixed> }
    proto token core {*}
    multi token core:basic { <product> + %  '-per-' }
    multi token core:quant { 'per-'       <product> }
    token mixed      { [<single>|<private>]+ % '-and-' }
    token product    {  <single>+ % '-' ['-' <private>+ % '-']? }
    token single     { [<dimension> '-']? <prefixed> }
    token private    { ['xxx'|'x'] '-' <single> }
    token dimension  { 'square' | 'cubic' | 'pow'[<[2..9]> |1<[0..5]> ] }
    token prefixed   { <prefix>? <simple> }
    # Per TR 35, prefixes come from
    # https://www.nist.gov/pml/special-publication-811/nist-guide-si-appendix-d-bibliography#05
    token prefix     {
        |                 exbi  | pebi  | tebi | gibi | mebi  | kibi
        | yotta | zetta | exa   | peta  | tera | giga | mega  | kilo | hecto | deka
        | deci  | centi | milli | micro | nano | pico | femto | atto | zepto | yocto
    }
    # The unit can be anything, but obviously CLDR will limit itself to only the most common
    # (and quite a few not-so-common).  In fact, the formal definition causes parse issues.
    # token simple     { <unit>+ % '-' | em | g | us | hg | of }
    # token unit       { <[a..z]> ** 3..* }
    token simple {
        | 'g-force' | 'meter' | 'second' | 'arc-minute' | 'arc-second' | 'degree' | 'radian'
        | 'revolution' | 'acre' | 'hectare' | 'foot' | 'inch' | 'mile' | 'yard' | 'dunam' | 'karat'
        | 'gram' | 'liter' | 'mole' | 'percent' | 'permille' | 'permyriad' | 'permillion' | 'item'
        | 'portion' | '100' | 'gallon' | 'gallon-imperial' | 'bit' | 'byte' | 'century' | 'decade'
        | 'day' | 'day-person' | 'hour' | 'minute' | 'month' | 'month-person' | 'week' | 'week-person'
        | 'year' | 'year-person' | 'ampere' | 'ohm' | 'volt' | 'calorie' | 'foodcalorie' | 'joule'
        | 'watt-hour' | 'electronvolt' | 'therm-us' | 'british-thermal-unit' | 'pound-force' | 'newton'
        | 'hertz' | 'dot' | 'em' | 'pixel' | 'astronomical-unit' | 'fathom' | 'furlong' | 'light-year'
        | 'mile-scandinavian' | 'nautical-mile' | 'parsec' | 'point' | 'earth-radius' | 'solar-radius'
        | 'candela' | 'lumen' | 'lux' | 'solar-luminosity' | 'carat' | 'grain' | 'metric-ton' | 'ounce'
        | 'ounce-troy' | 'pound' | 'stone' | 'ton' | 'dalton' | 'earth-mass' | 'solar-mass' | 'watt'
        | 'horsepower' | 'atmosphere' | 'inch-ofhg' | 'bar' | 'meter-ofhg' | 'pascal'
        | 'ofhg' | 'knot' | 'celsius' | 'fahrenheit' | 'generic' | 'kelvin' | 'pound-force-foot'
        | 'newton-meter' | 'acre-foot' | 'bushel' | 'cup' | 'cup-metric' | 'dessert-spoon'
        | 'dessert-spoon-imperial' | 'drop' | 'dram' | 'jigger' | 'pinch' | 'quart-imperial'
        | 'fluid-ounce' | 'fluid-ounce-imperial' | 'pint' | 'pint-metric' | 'quart'
        | 'tablespoon' | 'teaspoon' | 'barrel'
    }
}

role Fmt::Element {
    method format { ... }
    method gender { ... }
    method orig   { ... }
}
class Fmt::Per does Fmt::Element {
    has Fmt::Element $!left  is built; # generally, fmt::product
    has Fmt::Element $!right is built; # generally, fmt::product
    method orig (--> Str) {
        $!left.orig ~ '-per-' ~ $!right.orig
    }
    method format (\lang, \length, \case, \count --> Str) {
        # See if there is a unit format already for the language
        # and return its prebuilt pattern if so
        with lang.units.simple{$.orig} {
            return .{length}{case}{count}.pattern;
        }

        # Next, set up the LEFT side (e.g. *kilometers* per hour).
        my $left-plural = lang.grammar.derivations.per.plural-first;
        my $left-case   = lang.grammar.derivations.per.case-first;

        $left-plural = count if $left-plural eq 'compound';
        $left-case   = case  if $left-case   eq 'compound';

        my $left = $!left.format:
            lang,
            length,
            $left-case,
            $left-plural;

        # Set up the RIGHT side (e.g. kilometers *per hour*).
        # Some measurements have a specialized pre-built pattern.
        # If not (empty string), then we construct it off of the
        #   generic compound per element
        my
        $fmt-string;
        $fmt-string = .{length}.per-unit
            with lang.units.simple{$!right.orig};

        unless $fmt-string {
            my $right-plural = lang.grammar.derivations.per.plural-first;
            my $right-case   = lang.grammar.derivations.per.case-first;

            $right-plural = count if $right-plural eq 'compound';
            $right-case   = case  if $right-case   eq 'compound';

            my $per = lang.units.compound.per.{length}.pattern;
            $fmt-string = $per.subst:
                '{1}',
                $!right.format(         # Format the right
                    lang,               # But per TR 35 6.1, we remove
                    length,             # the {0} and trim the spaces
                    $right-case,
                    $right-plural
                ).subst('{0}','').trim;
        }
        $fmt-string.subst: '{0}', $left
    }

    method gender (\lang --> Str) {
        my $setting = lang.grammar.derivations.per.gender;
        return $!left.gender  if $setting eq '0';
        return $!right.gender if $setting eq '1';
        $setting
    }
}

class Fmt::Times does Fmt::Element {
    has Fmt::Element $!left  is built; # generally, fmt::dimensioned
    has Fmt::Element $!right is built; # generally, fmt::dimensioned
    method orig ( --> Str) {
        $!left.orig ~ '-' ~ $!right.orig
    }

    method format (\lang, \length, \case, \count --> Str) {
        # See if there is a unit format already for the language
        # and return its prebuilt pattern if so
        with lang.units.simple{$.orig} {
            return .{length}{case}{count}.pattern;
        }

        # There is not, so we'll construct manually.


        # Set up the LEFT side (e.g. *kilowatt*-hour).
        my $left-plural = lang.grammar.derivations.times.plural-first;
        my $left-case   = lang.grammar.derivations.times.case-first;
        $left-plural = count if $left-plural eq 'compound';
        $left-case   = case  if $left-case   eq 'compound';
        my $left = $!left.format: lang, length, $left-case, $left-plural;

        # Set up the RIGHT side (e.g. kilowatt-*hour*).
        # Unlike per, there are no built in styles.
        my $right-plural = lang.grammar.derivations.per.plural-second;
        my $right-case   = lang.grammar.derivations.per.case-second;
        $right-plural = count if $right-plural eq 'compound';
        $right-case   = case  if $right-case   eq 'compound';
        my $right = $!right.format: lang, length, $right-case, $right-plural;

        my $times = lang.units.compound.times.{length}.pattern;
        $times.subst('{0}',$left).subst: '{1}', $right.subst('{0}','').trim;
    }

    method gender (\lang --> Str) {
        my $setting = lang.grammar.derivations.times.gender;
        return $!left.gender  if $setting eq '0';
        return $!right.gender if $setting eq '1';
        $setting
    }
}

class Fmt::Power does Fmt::Element {
    has Str          $!left  is built; #= E.g. the power (cubed, squared, etc)
    has Fmt::Element $!right is built; #= E.g. the unit (meter, etc)
    method orig ( --> Str) {
        $!left ~ '-' ~ $!right.orig
    }
    method gender (\lang --> Str) {
        my $setting = lang.grammar.derivations.power.gender;
        return $!left.gender  if $setting eq '0';
        return $!right.gender if $setting eq '1';
        $setting
    }
    method format (\lang, \length, \case, \count --> Str) {
        # Set up the POWER side (e.g. *square*meter)

        my $left-plural = lang.grammar.derivations.power.plural-first;
        my $left-case   = lang.grammar.derivations.power.case-first;
        $left-plural = count if $left-plural eq 'compound';
        $left-case   = case if $left-case   eq 'compound';
        my $power-pattern = lang.units.compound{$!left}{length}{$left-case}{$left-plural}.pattern;

        # Set up the RIGHT side (e.g. kilowatt-*hour*).
        # Unlike per, there are no built in styles.
        my $right-plural = lang.grammar.derivations.power.plural-second;
        my $right-case   = lang.grammar.derivations.power.case-second;
        $right-plural = count if $right-plural eq 'compound';
        $right-case   = case  if $right-case   eq 'compound';
        my $right = $!right.format: lang, length, $right-case, $right-plural;

        my $start = $right.match(/<-[{}0\ ]>/).pos - 1;

        if length eq 'long' && $power-pattern ~~ /<alpha>\{0\}/ {
            $right.substr-rw($start,1) = $right.substr($start,1).lc;
        }

        $right.substr(0, $start) ~ $power-pattern.subst('{0}', $right.substr($start));
    }
}

class Fmt::Prefix does Fmt::Element {
    has Str          $!left  is built; #= E.g. the prefix (kilo, etc)
    has Fmt::Element $!right is built; #= E.g. the unit (meter, etc)
    method orig (--> Str) {
        $!left ~ $!right.orig
    }
    method gender (\lang --> Str) {
        my $setting = lang.grammar.derivations.prefix.gender;
        return $!left.gender  if $setting eq '0';
        return $!right.gender if $setting eq '1';
        $setting
    }
    method format (\lang, \length, \case, \count --> Str) {

        my $left-plural = lang.grammar.derivations.prefix.plural-first;
        my $left-case   = lang.grammar.derivations.prefix.case-first;
        $left-plural = count if $left-plural eq 'compound';
        $left-case   = case  if $left-case   eq 'compound';
        my $prefix-pattern = lang.units.compound{$!left}{length}{$left-case}{$left-plural}.pattern;

        my $right-plural = lang.grammar.derivations.prefix.plural-second;
        my $right-case   = lang.grammar.derivations.prefix.case-second;
        $right-plural = count if $right-plural eq 'compound';
        $right-case   = case  if $right-case   eq 'compound';

        my $right = lang.units.simple{$!right.orig}{length}{$right-case}{$right-plural}.pattern;

        # Do the actual replacement
        # Note the process:
        #   Detect the unit (should be the first non-whitespace, and non {0}) character
        #   If long, and the prefix pattern doesn't have a space before {0}, then LC the unit

        my $start = $right.match(/<-[{}0\ ]>/).pos - 1;

        if length eq 'long' && $prefix-pattern ~~ /<alpha>\{0\}/ {
            $right.substr-rw($start,1) = $right.substr($start,1).lc;
        }

        $right.substr(0, $start) ~ $prefix-pattern.subst('{0}', $right.substr($start));
    }
}

class Fmt::Simple does Fmt::Element {
    has Str $.orig  is built;

    method gender (\lang --> Str ) {
        lang.units.simple{$!orig}.gender.Str;
    }
    method format (\lang, \length, \case, \count --> Str) {
        lang.units.simple{$!orig}{length}{case}{count}.pattern;
    }
}

class FormatActions {
    method TOP ($/) {
        with $<core>  { make .made};
        with $<mixed> { make .made};
    }

    method core:basic ($/) {
        if $<product> == 2 {
            make Fmt::Per.new:
                :orig($/.Str),
                :left($<product>[0].made),
                :right($<product>[1].made) # todo: needs special handling if more than one product
        }elsif $<product> == 1 {
            make $<product>[0].made;
        } else { die "don't support more than two products yet" }
    }

    method product ($/) {
        if $<single> == 2 {
            make Fmt::Times.new:
                :orig($/.Str),
                :left($<single>[0].made),
                :right($<single>[1].made)
        } elsif $<single> == 1 { make $<single>[0].made
        } else { die "don't support more than two singles yet" }

    }

    my %power-table =
        square => 'power2',
        cubic  => 'power3',
    ;
    method single ($/) {
        with $<dimension> {
            make Fmt::Power.new:
                :orig($/.Str),
                :left(%power-table{$<dimension>}),
                :right($<prefixed>.made)
        } else { make $<prefixed>.made }
    }

    my %prefix-table =
        kibi => '1024p1',
        mebi => '1024p2',
        gibi => '1024p3',
        tebi => '1024p4',
        pebi => '1024p5',
        exbi => '1024p6',
        zebi => '1024p7',
        yobi => '1024p8',

        deka  => '10p1',
        hecto => '10p2',
        kilo  => '10p3',
        mega  => '10p6',
        giga  => '10p9',
        tera  => '10p12',
        peta  => '10p15',
        exa   => '10p18',
        zetta => '10p21',
        yotta => '10p24',

        deci  => '10p-1',
        ceni  => '10p-2',
        milli => '10p-3',
        micro => '10p-6',
        nano  => '10p-9',
        pico  => '10p-12',
        femto => '10p-15',
        atto  => '10p-18',
        zepto => '10p-21',
        yocto => '10p-24',
    ;
    method prefixed ($/) {
        with $<prefix> {
            make Fmt::Prefix.new:
                :orig($/.Str),
                :left(%prefix-table{$<prefix>}),
                :right($<simple>.made)
        } else { make $<simple>.made }
    }
    method simple ($/) {
        make Fmt::Simple.new: :orig($/.Str)
    }

}