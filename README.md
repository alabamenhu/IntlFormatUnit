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
  
## ⚠ Warning

More so than other modules in the `Intl` namespace, this module should be considered experimental for the following reasons:

  1. The method of selecting the unit is not intuitive and will likely be changed.  
  For backwards compatibility reasons, the units in CLDR include a ‘type’ prefix.  I have not yet decided whether it's best to try to calculate that on the fly or update `Intl::CLDR` to remove it, since the type prefix is technically irrelevant.
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
  
## Version History

  * **v0.2.0**
    * Support for composed units
  * **v0.1.0** 
    * Initial version

## License and Copyright
 
© 2020-2021 Matthew Stephen Stuckwisch.
Licensed under the Artistic License 2.0.