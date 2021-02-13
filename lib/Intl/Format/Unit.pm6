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
