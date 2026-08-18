---
title: "Synlighets analyse"
collection: portfolio
excerpt: "Address-Based Neighborhood Analyzer. <br/><img src='/images/synlighetsanalyse.png'>"
teaser: /images/synlighetsanalyse.png
---

## Bakgrunn

Prosjektets formål var å vurdere den visuelle påvirkningen av planlagt bebyggelse på omgivelsene ved hjelp av en synlighetsanalyse (Viewshed). Analysen ble gjennomført for å identifisere hvilke områder som ville ha sikt til de planlagte bygningene, og dermed gi et bedre beslutningsgrunnlag i planleggingsprosessen.


## Datasett


Planlagte bygninger representert som punkter med høydeverdier (Z-verdi)

Digital terrengmodell (DTM)

Digital overflatemodell (DOM)

Geografiske bakgrunnsdata


## Metode

Punktdataene ble først transformert til koordinatsystemet ETRS89 / UTM sone 33N. Deretter ble det opprettet en buffersone på 4000 meter rundt punktene for å avgrense analyseområdet.

Terreng- og overflatemodeller ble klargjort for analyse og ble deretter benyttet i en synlighetsanalyse (Viewshed) i ArcGIS Pro. Senere ble rasterern avgrenset til influensområdet ved hjelp av verktøyet Extract By Mask

Analysen tok hensyn til både terrengforhold og høyden på de planlagte bygningene for å beregne hvilke områder som ville ha direkte sikt til tiltaket.


## Resultater

Analysen identifiserte områder med og uten visuell eksponering mot den planlagte bebyggelsen. Resultatene gir et grunnlag for vurdering av landskapsvirkninger og visuell påvirkning, og kan brukes som støtte i konsekvensutredninger og planprosesser.


![Synlighetsanalyse](/images/Synlighetsanalyse.jpg)
