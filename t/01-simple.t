use Test;
use Intl::Format::Unit;

is format-unit(0, :unit<meter>, :language<en>, :length<long>  ), '0 meters';
is format-unit(1, :unit<meter>, :language<en>, :length<long>  ), '1 meter';
is format-unit(2, :unit<meter>, :language<en>, :length<long>  ), '2 meters';
is format-unit(0, :unit<meter>, :language<en>, :length<short> ), '0 m';
is format-unit(1, :unit<meter>, :language<en>, :length<short> ), '1 m';
is format-unit(2, :unit<meter>, :language<en>, :length<short> ), '2 m';
is format-unit(0, :unit<meter>, :language<en>, :length<narrow>), '0m';
is format-unit(1, :unit<meter>, :language<en>, :length<narrow>), '1m';
is format-unit(2, :unit<meter>, :language<en>, :length<narrow>), '2m';

done-testing;
