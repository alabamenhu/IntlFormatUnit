# Making Intl::Format::Unit

The following is intended partly as a guide to interfacing with
CLDR (for those interested), but also to show how easy Raku can 
make doing fairly complex things (such as easily parsing text
standards, creating ASTs and acting on them) while maintaining 
eminently readable and maintainable code.

## What do we want?

The idea of formatting units is to create a string that combines
a number (like 3, 6.76, or 1000) with a unit of measurement like
a meter or a foot.  On the surface, you might think that this is
quite easy:

```raku
sub format-unit($number, $unit) {
    "$number $unit"
}
```

Unfortunately, even for a fairly simple language like English,
we can already see a problem: if I call `format-unit(2,'meter')`,
the end result will be *two meter* and not *two meters*.  A naïve 
programmer might think that we could adjust this to

```raku
sub format-unit($number, $unit) {
    "$number $unit" ~ ('s' if $number > 1)
}
```

That gets us *one meter* and *two meters* but… also gets *zero 
meter* (and English rules dictate that that should have an *s*)
also.  Okay, great, we now make it `!= 1` instead.  But then,
someone wants to format a foot.  So we get `2 foots`.  And, of
course, adding an S doesn't work for all languages.  That's a lot
of custom coding we'd need to do.

## Enter CLDR

Unicode has a database of information that tells us how different
languages format their units, numbers, dates, and all sorts of 
different things.  There are two aspects of CLDR which we will 
*not* treat here, and take as a given their existence.  They are
included in the modules `Intl::Format::Number`, which formats
numbers for us, and `Intl::Number::Plural`, which tells us the
grammatical-ish number (*singlar*-ish, *plural*-ish) that a 
given number behaves as.

To directly access CLDR, there is a module called `Intl::CLDR`.
So right off the bat, we'll need to import these three modules:

```
unit module Intl::Format::Unit;

use Intl::CLDR;
use Intl::Number::Plural;
use Intl::Format::Number;
```

Before we write anything more, it's good to think about what all
information we'll ultimately need.  A good way to do this is
to simply browse the CLDR in REPL:

```
> use Intl::CLDR
Nil
> my $english = cldr<en>
[CLDR-Language: ……units]
> $english.units
[CLDR-Units: compound,coordinate,duration,simple]
> $english.units.simple
[CLDR-SimpleUnits: ………length-meter………]
> $english.units.simple.length-meter
[SimpleUnitSet: long,short,narrow; one,other]
> $english.units.simple.length-meter.long.other.pattern
{0} meters
> $english.units.simple.length-meter.long.one.pattern
{0} meter
> $english.units.simple.length-meter.short.one.pattern
{0} m
> $english.units.simple.length-meter.narrow.one.pattern
{0}m
```

What this hopefully illustrates is that for us to get to a 
pattern that we need to format, we need several pieces of
information.  First, whether the unit is "simple" or something
else (for right now, we'll assume everything is simple). 
Then we need the name of the type, we also need a length for it
which can be any of *long*, *short* or *narrow*, and we also
have a special attribute called *one* and *other*.  That is 
the grammatical-ish count (I keep saying issue because it's 
not actually grammatical number, but certainly related).


So we'll need to know the unit, it's quantity, our language,
the length desired, and a plural count.  That's a *lot* of
information to require from the user.  Before we write the 
signature, let's think if we can create any sensible defaults.

The language can probably be obtained directly from a user's 
system.  There's a module for that, so we can add 
`Intl::UserLanguage` to our list of required modules, and use 
its `user-language` to substitute if not specified.

The plural count can be obtained directly from the quantity,
so we can calculate that as a part of our code.  For the
length, we can just go Goldilocks.  People probably don't
want 'meters' spelled out in full, but they probably want normal
spacing too.  This gives us the following signature:


```
#| Formats a unit of measurement in a localized manner
sub format-unit (
    $quantity,                   #= The number of units to format
    :$unit!,                     #= The unit used for formatting
    :$language =  user-language, #= The language to use for formatting
    :$length   = 'short'         #= The language to use for formatting
) is export {
    ...
}
```

Our first step is to actually format the number.  This means in
English inserting commas in between the thousands groupings, 
placing a period for the decimal point, etc.  Other languages
may have different digits or symbols, but `Intl::Format::Number`
means we don't need to worry about *how* they do it, just to 
remember that many languages *do* do things differently:

```
    my $number  = format-number $quantity;
```

Next, as we noted, we'll need the grammatical-ish count, 
which thanks to `Intl::Number::Count`, we needn't work too hard
to get:

```
    my $count   = plural-count $quantity;
```

Now, we can grab the pattern by plugging in all of the values.
`Intl::CLDR` makes sure that all of its items are accessible
both via Hashkey accessors *and* attributes.  (The latter are
faster if you know exactly what you want, so definitely prefer
them when possible)

````
    my $pattern = cldr{$language}.units.simple{$unit}{$length}{$count}.pattern;
````

That's a long line but… surprisingly straight forward.  The 
pattern that we get from CLDR notes replaceables by putting 
a number inside of braces.  In this case, there is only ever
one element to be replaced, so it's easy:

```
    $pattern.subst: '{0}', $number;
```

And... **that's it!**  Well.  Almost.  It turns out, although 
*English* doesn't need it, other languages have some other
information they need.  If you go back to the REPL, try this:

```
> cldr<de>.units.simple.length-meter
[SimpleUnitSet: long,short,narrow; one,other; nominative,accusative,dative,genitive]
```

Okay, well, that's annoying.  Also, it's not detectable by
looking at the number.  Thankfully, there's a *clear* default
in using *nominative* (what you'd expect on a label, for
instance).  So that's easy enough to take care of.
Here, at last, is our very easy to read code:

```
unit module Intl::Format::Unit;

use Intl::CLDR;           # Provides access to pattern database
use Intl::UserLanguage;   # Gets default language
use Intl::Format::Number; # Formats the number
use Intl::Number::Plural; # Determines number count

#| Formats a unit with a given quantity in a localized manner
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
```

I reckon that many people can figure out what's going on in this
code without much trouble at all.  

## The next step

Unfortunately, that's not all.  Complex units (like *kilometers per hour*) 
or *pounds per square inch* integrate multiple units simultaneously.
There's also effectively infinite of them.  We can still format them,
actually.  But it's going to require a lot more work.  Thankfully,
Raku is very much up to the task as we'll see in the next part of
this series.