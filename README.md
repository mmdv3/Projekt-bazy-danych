Michał Dymowski

#### Instrukcja użytkowania
Żeby wywołać program z parametrem "--init" należy będąc w folderze z projektem użyć polecenia
```
./script.sh --init
```

Żeby wywołać funkcje API należy w folderze z projektem stworzyć plik, w którym w kolejnych liniach zapisane będą json'y z parametrami funkcji. Następnie będąc w folderze z projektem wywołać polecenie
```
./script.sh [nazwa_pliku]
```

Dla przykładu: Jeżeli chcemy wywołać funkcje odpowiadające przykładowemu wejściu
```
{"function":"flight", "params":{"id":"12345", "airports":[{"airport":"WAW","takeoff_time":"2021-06-01 20:26:44.229109+02"},{"airport":"WRO","takeoff_time":"2021-06-01 21:46:44.229109+02", "landing_time":"2021-06-01 21:26:44.229109+02"}, {"airport":"GDN", "landing_time":"2021-06-01 22:46:44.229109+02"}]}}
{"function":"list_flights", "params":{"id":"12345"}}
{"function":"flight", "params":{"id":"12346", "airports":[{"airport":"KTW","takeoff_time":"2021-06-02 12:00:00.229109+02"},{"airport":"POZ", "landing_time":"2021-06-01 13:00:00.229109+02"}]}}
{"function":"list_flights", "params":{"id":"12346"}}
```
to tworzymy plik input, w którym umieszczamy powyższe linijki i wywołujemy polecenie
```
 ./script.sh input
```
Wyjście programu zostanie wypisane na standardowe wyjście.
