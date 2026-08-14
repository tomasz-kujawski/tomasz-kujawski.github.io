---
title: "Vindkraftanalyse"
excerpt: "![icon vindkraft](images/vindkkraftanalyse.png)"
collection: portfolio
---

## Bakgrunn

Prosjektet hadde som mål å identifisere områder i Norge som kan være egnet for etablering av vindkraftanlegg. Analysen tok utgangspunkt i tekniske, miljømessige og arealrelaterte kriterier for å finne områder med gode vindressurser og tilstrekkelig infrastruktur, samtidig som konflikter med bebyggelse, naturverdier og andre arealinteresser ble redusert.


## Datasett

Følgende offentlige geodata ble benyttet i analysen:

Vindressursdata

Transformatorstasjoner og elektrisk infrastruktur

Bygninger og bebygde områder

Fritidsbebyggelse og fritidsområder

Innsjøer og elver

Isbreer

Vernede områder

UNESCO-områder

Innflygingssoner ved flyplasser

Dataene ble hentet fra GeoNorge, NVE og andre offentlige datakilder.



## Metode

Analysen ble gjennomført som en GIS-basert egnethetsanalyse.
Først ble områder med gjennomsnittlig vindhastighet under 6,5 m/s ekskludert. Deretter ble det identifisert områder med tilgang til strømnettet ved å avgrense analysen til områder innenfor 2 km fra eksisterende transformatorstasjoner.
For å redusere konflikt med bebyggelse ble det opprettet buffersoner på 800 meter rundt boliger, næringsbygg og tett konsentrerte fritidsområder. Disse områdene ble ekskludert fra videre analyse.
I tillegg ble følgende arealtyper fjernet:

innsjøer og elver

isbreer

vernede områder

UNESCO-områder

innflygingssoner ved flyplasser

De gjenværende områdene ble deretter sammenstilt og visualisert for å identifisere potensielle lokaliteter for vindkraftutbygging



## Resultater

Analysen identifiserte flere områder med potensial for vindkraftutbygging som oppfyller definerte tekniske og miljømessige kriterier. Resultatene viser hvordan tilgjengelige offentlige geodata kan brukes til å gjennomføre en systematisk og transparent egnethetsanalyse.
Prosjektet demonstrerte også hvordan ulike GIS-verktøy kan benyttes til å validere og sammenligne analyser på tvers av plattformer. Resultatene fra ArcGIS Pro, FME og R ga tilsvarende geografiske mønstre og bekreftet robustheten i analysen.



## Verktøy

ArcGIS Pro

FME

R

GeoNorge

NVE-data


## ArcGIS ModelBuilder


![images/model_builder_arcGIS_vindkraft.png

 

## FME Workspace

 

![FME workspace](/images/workflow_FME_vindkraft.png)

 

## Analyse i R

 

![Analyse i R](/images/R_1_vindkraft.png)

 

![Analyse i R del.2](/images/R_2_vindkraft.png)

 

## Resultater

 

![kart med resultater](/images/vindkraft_samenligning.jpg)

 

Analysen identifiserte flere områder med potensial for vindkraftutbygging.
