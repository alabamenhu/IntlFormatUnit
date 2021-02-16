# Intl::Format::Unit
A module for formatting units in a localized manner

To use

```raku
use Intl::Format::Unit;

say format-unit 0,        :unit<length-meter>; # 0 m
say format-unit 1234,     :unit<length-meter>; # 53,425.21 m
say format-unit 53425.21, :unit<length-meter>; # 1,234 m
```

The sub `format-unit` takes the following arguments:

  * **`quantity`**  
  The amount of the unit (a number).
  * **`unit`**  
  The type of unit (e.g. meter, liter, etc).
  * **`:language`**  
  The language to use in formatting.  Defaults to **user-language**.
  * **`:length`**  
  Any of **long**, **short** or **narrow**.  Defaults to *short*.
  * **`:case`**  
  The grammatical case to use (normally only applicable with *long* length).  Defaults to *nominative*
  
The units can be quite complex, even to the point of making no sense. Assuming English,

```raku
format-unit 12345.6789, :unit<solar-radius-cubic-yottaliter-per-pound-square-millimeter>;
# 12,345.6789 R☉⋅Yl³/lb⋅mm²
```
  
## Supported units

The units that are generally supported by CLDR's `validity/units.xml` file.  These have been curated a bit to have the following base units:

> **g-force meter second arc-minute arc-second degree radian
              revolution acre hectare foot inch mile yard dunam karat
              gram liter mole percent permille permyriad permillion item
              portion gallon gallon-imperial bit byte century decade
              day day-person hour minute month month-person week week-person
              year year-person ampere ohm volt calorie foodcalorie joule
              watt-hour electronvolt therm-us british-thermal-unit pound-force newton
              hertz dot em pixel astronomical-unit fathom furlong light-year
              mile-scandinavian nautical-mile parsec point earth-radius solar-radius
              candela lumen lux solar-luminosity carat grain metric-ton ounce
              ounce-troy pound stone ton dalton earth-mass solar-mass watt
              horsepower atmosphere inch-ofhg bar meter-ofhg pascal
              ofhg knot celsius fahrenheit generic kelvin pound-force-foot
              newton-meter acre-foot bushel cup cup-metric dessert-spoon
              dessert-spoon-imperial drop dram jigger pinch quart-imperial
              fluid-ounce fluid-ounce-imperial pint pint-metric quart
              tablespoon teaspoon barrel** 
              
All of these make take the following SI and SI-ish (*˟*) prefixes:

> **yotta zetta  exa peta  tera  giga  mega  kilo  hecto  deka
        deci centi  milli  micro  nano  pico  femto atto zepto yocto
        exbi˟ pebi˟ tebi˟ gibi˟ mebi˟  kibi˟**

Lastly, the following powers are supported:

> **square cubic**

Using the above units, you can combine them in the following way:

  * To prefix, attach directly: `millimeter` `kiloliter`
  * To raise to a power, separate the power and the unit by a hyphen: `square-foot`, `cubic-centimeter`
  * To multiple two units, separate by a hyphen: `watt-hour`
  * To divide two units, separate by a hyphenated per: `miles-per-hour`.
  
These can combined in almost infinite complexity.  The only restriction is that there may only be 
*one* `-per-` (subsequent ones, per TR 35, are ignored). 

Also note that the rarer the combination of units that you get, the more likely that non-major languages
may not have full support.  For Latin-based languages, this might not look terrible,
but for others, it means that the fallback versions (all Latin-script) may be inserted.

## ⚠ Warning

More so than other modules in the `Intl` namespace, this module should be considered experimental for the following reasons:

  1. The method of selecting the unit is not intuitive and will likely be changed.  
  2. Composed units were only introduced in CLDR v.38 (early 2020) with support for two languages (French and German).  
  As of v.38.1 (late 2020), this has not changed.  Use caution when attempting to use these, as some languages may end up creating unexpected combinations (like saying *liter per minutes* instead of *liters per minute*).  This should not affect the most simple units such as *meter* or *liter* or even common ones like *kilometers per hour*.
  
## Dependencies

  * `Intl::CLDR`  
  Houses the data for calculating the counts
  * `Intl::UserLanguage`  
  Determines the default language when not provided
  * `Intl::Format::Number`  
  Formats the quantity as a decimal number
  * `Intl::Number::Plural`  
  Determines the grammatical-ish number to select the correct pattern
  
## Todo

  * More tests files (especially for compound units)
  
## Version History

  * **v0.2.0**
    * Initial support for composed units
  * **v0.1.0** 
    * Initial version

## License and Copyright
 
© 2020-2021 Matthew Stephen Stuckwisch.
Licensed under the Artistic License 2.0.