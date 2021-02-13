# Intl::Format::Unit
A module for formatting units in a localized manner

To use

```raku
use Intl::Format::Unit;

say format-unit 0,        :unit<length-meter>; # 0 m
say format-unit 1234,     :unit<length-meter>; # 53,425.21 m
say format-unit 53425.21, :unit<length-meter>; # 1,234 m

```

Not currently production ready: the method for selecting units is not fleshed out.  
Do **NOT** expect the API to be stable at the moment.

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

  * **v0.1.0** 
    * Initial version

## License and Copyright
 
© 2020-2021 Matthew Stephen Stuckwisch.
Licensed under the Artistic License 2.0.