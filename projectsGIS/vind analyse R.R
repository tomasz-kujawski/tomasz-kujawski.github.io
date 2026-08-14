#install packeges
install.packages(c("sf", "ggplot2", "ggspatial", "RColorBrewer", "mapview", "tmap"))

#load in librarys

library(sf)
library(ggplot2)
library(ggspatial)
library(RColorBrewer)
library(terra)
library(mapview)
library(tmap)

#load in raster file
vind_raster<-rast("C:/Users/tok/Documents/hele norge vind/NVE_47551B14_1779872810726_2800/NVEKartdata/NVEData/Vindressurs/Vindressurs_Gjennomsnittsvind_120m.tif")

plot(vind_raster)
mapview(vind_raster)

#calculate raster >6.5
vind_sterk <- ifel(vind_raster>6.5, vind_raster, NA)
plot(vind_sterk)
mapview(vind_sterk)

#load in .gdb
source("C:/Users/tok/Documents/hele norge vind/Vinddata_tomasz.gdb")
fylker<-vect()

#
vect("C:/Users/tok/Documents/hele norge vind/Vinddata_tomasz.gdb")

#fylker layer
fylker <- vect("C:/Users/tok/Documents/hele norge vind/Vinddata_tomasz.gdb",
            layer = "fylker")
mapview(fylker)

#polygon to raster
fylker_rast<-rasterize(fylker, vind_raster, field = 1)
mapView(fylker_rast)

#fjern sjø
vind_land<-mask(vind_sterk, fylker_rast)
mapview(vind_land)

#les inn layers unntakk
vern <- vect("C:/Users/tok/Documents/hele norge vind/Vinddata_tomasz.gdb", layer = "Harde_vern")
unesco <- vect("C:/Users/tok/Documents/hele norge vind/Vinddata_tomasz.gdb", layer = "Harde_verdensarvUNESCO")
tett <- vect("C:/Users/tok/Documents/hele norge vind/Vinddata_tomasz.gdb", layer = "Harde_tettsteder")
isbre <- vect("C:/Users/tok/Documents/hele norge vind/Vinddata_tomasz.gdb", layer = "Harde_isbreer")
innsjo <- vect("C:/Users/tok/Documents/hele norge vind/Vinddata_tomasz.gdb", layer = "Harde_Innsjoer")
innfly <- vect("C:/Users/tok/Documents/hele norge vind/Vinddata_tomasz.gdb", layer = "Harde_innflyvningssoner")

#merge
untakk_all<- rbind(vern, unesco, tett, isbre, innsjo, innfly)
mapview(untakk_all)

#raster untakk
untakk_rast<- rasterize(untakk_all, vind_sterk, field = 1)
mapView(untakk_rast)

#vind - unntakk
sterkvind_uten_untakk<- mask(vind_land, untakk_rast, inverse = TRUE)
mapview(sterkvind_uten_untakk)

#add el trans
el_trans<-vect("C:/Users/tok/Documents/hele norge vind/Energi_0000_Norge_25833_Nettanlegg_FGDB/Energi_0000_Norge_25833_Nettanlegg_FGDB.gdb", layer = "el_transformatorstasjon")
mapview(el_trans)
el_buff<-buffer(el_trans, width = 2000)
mapview(el_buff)

el_buff_raster <- rasterize(el_buff, vind_sterk, field = 1)
mapview(el_buff_raster)

#vind close to el trans
vind_close_to_trans<-ifel(!is.na(el_buff_raster) & !is.na(sterkvind_uten_untakk),1, NA)
mapview(vind_close_to_trans)

#bygg layers
bedrifter<-vect("C:/Users/tok/Documents/hele norge vind/Bedrifter 250m 2026/Bedrifter 250m 2026.shp")
boliger<-vect("C:/Users/tok/Documents/hele norge vind/Boliger 250m 2025/Boliger 250m 2025.shp")
byggmasser<-vect("C:/Users/tok/Documents/hele norge vind/Bygningsmassen 250m 2025/Bygningsmassen 250m 2025.shp")
fritid<-vect("C:/Users/tok/Documents/hele norge vind/Tettbygde fritidsbyggomrader 2025/Tettbygde fritidsbyggomrader 2025.shp")

#bygg merge and buff
bygg<-rbind(bedrifter, boliger, byggmasser, fritid)
bygg_buff<-buffer(bygg, width=800)
mapView(bygg_buff)
bygg_raster<-rasterize(bygg_buff, sterkvind_uten_untakk, field = 1)

mapview(bygg_raster)

#find vind close to el trans but not close to bygg
event_plasering<-mask(vind_close_to_trans, bygg_raster, inverse= TRUE)
mapview(event_plasering)
plot(event_plasering)

#safe .tif

writeRaster(event_plasering, "eventualle_plasseringer.tif", overwrite = TRUE)
