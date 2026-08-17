---
title: "Nabolagsutforsker"
collection: portfolio
excerpt: "Address-Based Neighborhood Analyzer. <br/><img src='images/nabolagsutforsker.png'>"
teaser: images/nabolagsutforsker.png

---



# Nabolagsutforsker (Neighborhood Explorer)

Utviklet en webapplikasjon som analyserer et område basert på en oppgitt adresse. Løsningen geokoder adressen, finner nærliggende interessepunkter og presenterer resultatene på et interaktivt kart.

## Funksjonalitet:

Geokoding av adresser til GPS-koordinater


Søk etter nærliggende skoler, barnehager, butikker, kollektivtransport, kultur- og idrettstilbud


Beregning av faktisk gangavstand og gangtid ved hjelp av rutedata


Estimering av stigning (høydemeter) langs gangruter


Visualisering av resultater på et interaktivt kart


Integrasjon mot flere åpne geografiske API-er med fallback-løsninger for økt stabilitet



## Teknologier:

Python
Flask
Folium
OpenStreetMap
Overpass API
Nominatim
Photon
OSRM
Open-Elevation
HTML / CSS

Prosjektmål: Å utvikle et verktøy som hjelper brukere med å vurdere tilgjengeligheten av tjenester og infrastruktur rundt en bolig eller adresse på en rask og brukervennlig måte.


```python
from flask import Flask, request, render_template
import folium
import os
import requests
import math

app = Flask(
    __name__,
    template_folder=os.path.join(os.path.dirname(__file__), 'templates'),
    static_folder=os.path.join(os.path.dirname(__file__), 'static'),
)
USER_AGENT = "AddressMapApp/1.0 (contact@example.com)"
COLOR_MAP = {
    "stops": "blue",
    "shops": "green",
    "schools": "orange",
    "kindergartens": "cyan",
    "post": "red",
    "culture": "magenta",
    "sports": "teal",
    "services": "purple",
}


def geocode(address):
    url = "https://nominatim.openstreetmap.org/search"
    # include an email (per Nominatim usage policy) and sensible headers
    email = os.environ.get("NOMINATIM_EMAIL", "contact@example.com")
    params = {"q": address, "format": "json", "limit": 1, "email": email}
    headers = {"User-Agent": USER_AGENT, "From": email}

    try:
        response = requests.get(url, params=params, headers=headers, timeout=10)
        response.raise_for_status()
        data = response.json()
        if data:
            return float(data[0]["lat"]), float(data[0]["lon"])
    except requests.exceptions.HTTPError as e:
        status = getattr(e.response, "status_code", None)
        app.logger.warning("Nominatim error %s for %s", status, address)
        # fall through to fallback
    except requests.exceptions.RequestException as e:
        app.logger.warning("Nominatim request failed: %s", e)

    # Fallback: try Photon geocoder (public) to improve reliability in dev
    try:
        photon_url = "https://photon.komoot.io/api/"
        photon_headers = {"User-Agent": USER_AGENT, "From": email}
        r = requests.get(photon_url, params={"q": address, "limit": 1}, headers=photon_headers, timeout=8)
        r.raise_for_status()
        j = r.json()
        features = j.get("features") or []
        if features:
            coords = features[0]["geometry"]["coordinates"]  # [lon, lat]
            return float(features[0]["geometry"]["coordinates"][1]), float(features[0]["geometry"]["coordinates"][0])
    except requests.exceptions.RequestException as e:
        app.logger.warning("Photon fallback failed: %s", e)

    # last resort: return None
    return None


def haversine(lat1, lon1, lat2, lon2):
    R = 6371.0
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c


def get_elevations(coords):
    url = "https://api.open-elevation.com/api/v1/lookup"
    payload = {"locations": [{"latitude": lat, "longitude": lon} for lat, lon in coords]}
    try:
        response = requests.post(url, json=payload, headers={"User-Agent": USER_AGENT}, timeout=10)
        response.raise_for_status()
        data = response.json()
        results = data.get("results") or []
        if len(results) != len(coords):
            return None
        return [res.get("elevation") for res in results]
    except requests.exceptions.RequestException:
        return None


def route_info(lat1, lon1, lat2, lon2):
    url = f"https://router.project-osrm.org/route/v1/foot/{lon1},{lat1};{lon2},{lat2}?overview=full&geometries=geojson"
    try:
        response = requests.get(url, headers={"User-Agent": USER_AGENT}, timeout=10)
        response.raise_for_status()
        data = response.json()
        routes = data.get("routes")
        if not routes:
            return None
        route = routes[0]
        duration_sec = route.get("duration")
        distance_m = route.get("distance")
        if duration_sec is None or distance_m is None or distance_m <= 0:
            return None

        # Sanity-check OSRM walking time: if the returned route implies a walking speed
        # much faster than a brisk walk, replace it with a conservative estimate.
        speed_m_s = distance_m / duration_sec if duration_sec > 0 else 0
        if speed_m_s > 2.5:
            duration_sec = distance_m / 1.4

        elevation_gain_m = None
        geometry = route.get("geometry") or {}
        coords = geometry.get("coordinates") or []
        if coords:
            max_points = 30
            step = max(1, len(coords) // max_points)
            sampled = coords[::step]
            if sampled[-1] != coords[-1]:
                sampled.append(coords[-1])
            elev_coords = [(lat, lon) for lon, lat in sampled]
            elevations = get_elevations(elev_coords)
            if elevations and len(elevations) == len(elev_coords) and all(e is not None for e in elevations):
                total_gain = 0.0
                for i in range(len(elevations) - 1):
                    diff = elevations[i + 1] - elevations[i]
                    if diff > 0:
                        total_gain += diff
                elevation_gain_m = round(total_gain, 1)
                if elevation_gain_m > 0:
                    duration_sec += round(elevation_gain_m * 6)

        if elevation_gain_m is None:
            elevations = get_elevations([(lat1, lon1), (lat2, lon2)])
            if elevations and len(elevations) == 2 and elevations[0] is not None and elevations[1] is not None:
                elevation_gain_m = max(0, elevations[1] - elevations[0])
                if elevation_gain_m > 0:
                    duration_sec += round(elevation_gain_m * 6)

        duration_min = max(1, round(duration_sec / 60))
        distance_km = round(distance_m / 1000, 2)
        return {"distance_km": distance_km, "walk_min": duration_min, "elevation_gain_m": elevation_gain_m}
    except requests.exceptions.RequestException:
        return None


def get_poi(lat, lon, radius=1400):
    overpass_urls = [
        "https://overpass-api.de/api/interpreter",
        "https://overpass.kumi.systems/api/interpreter",
        "https://overpass.openstreetmap.fr/api/interpreter",
        "https://overpass.osm.ch/api/interpreter",
        "https://overpass.nchc.org.tw/api/interpreter",
    ]
    query = f"""
    [out:json][timeout:25];
    (
      node(around:{radius},{lat},{lon})[highway=bus_stop];
      node(around:{radius},{lat},{lon})[amenity=bus_station];
      node(around:{radius},{lat},{lon})[public_transport=platform];
      node(around:{radius},{lat},{lon})[public_transport=stop_position];
      node(around:{radius},{lat},{lon})[railway=tram_stop];
      node(around:{radius},{lat},{lon})[railway=stop];
      node(around:{radius},{lat},{lon})[railway=station];
      node(around:{radius},{lat},{lon})[amenity=school];
      way(around:{radius},{lat},{lon})[amenity=school];
      relation(around:{radius},{lat},{lon})[amenity=school];
      node(around:{radius},{lat},{lon})[amenity=kindergarten];
      way(around:{radius},{lat},{lon})[amenity=kindergarten];
      relation(around:{radius},{lat},{lon})[amenity=kindergarten];
      node(around:{radius},{lat},{lon})[amenity=post_office];
      way(around:{radius},{lat},{lon})[amenity=kindergarten];
      relation(around:{radius},{lat},{lon})[amenity=kindergarten];
      node(around:{radius},{lat},{lon})[amenity=post_office];
      way(around:{radius},{lat},{lon})[amenity=post_office];
      relation(around:{radius},{lat},{lon})[amenity=post_office];
      node(around:{radius},{lat},{lon})[amenity=post_box];
      way(around:{radius},{lat},{lon})[amenity=post_box];
      relation(around:{radius},{lat},{lon})[amenity=post_box];
      node(around:{radius},{lat},{lon})[amenity=library];
      way(around:{radius},{lat},{lon})[amenity=library];
      relation(around:{radius},{lat},{lon})[amenity=library];
      node(around:{radius},{lat},{lon})[tourism=museum];
      way(around:{radius},{lat},{lon})[tourism=museum];
      relation(around:{radius},{lat},{lon})[tourism=museum];
      node(around:{radius},{lat},{lon})[amenity=cinema];
      way(around:{radius},{lat},{lon})[amenity=cinema];
      relation(around:{radius},{lat},{lon})[amenity=cinema];
      node(around:{radius},{lat},{lon})[amenity=theatre];
      way(around:{radius},{lat},{lon})[amenity=theatre];
      relation(around:{radius},{lat},{lon})[amenity=theatre];
      node(around:{radius},{lat},{lon})[leisure=fitness_centre];
      way(around:{radius},{lat},{lon})[leisure=fitness_centre];
      relation(around:{radius},{lat},{lon})[leisure=fitness_centre];
      node(around:{radius},{lat},{lon})[leisure=sports_centre];
      way(around:{radius},{lat},{lon})[leisure=sports_centre];
      relation(around:{radius},{lat},{lon})[leisure=sports_centre];
      node(around:{radius},{lat},{lon})[leisure=stadium];
      way(around:{radius},{lat},{lon})[leisure=stadium];
      relation(around:{radius},{lat},{lon})[leisure=stadium];
      node(around:{radius},{lat},{lon})[sport=climbing];
      way(around:{radius},{lat},{lon})[sport=climbing];
      relation(around:{radius},{lat},{lon})[sport=climbing];
      node(around:{radius},{lat},{lon})[sport=football];
      way(around:{radius},{lat},{lon})[sport=football];
      relation(around:{radius},{lat},{lon})[sport=football];
      node(around:{radius},{lat},{lon})[shop=supermarket];
      node(around:{radius},{lat},{lon})[shop=convenience];
      node(around:{radius},{lat},{lon})[amenity=restaurant];
      node(around:{radius},{lat},{lon})[amenity=cafe];
      node(around:{radius},{lat},{lon})[amenity=bank];
      node(around:{radius},{lat},{lon})[amenity=pharmacy];
    );
    out center meta;
    """

    headers = {
        "User-Agent": USER_AGENT,
        "Accept": "*/*",
        "From": os.environ.get("NOMINATIM_EMAIL", "contact@example.com"),
    }

    last_exc = None
    for url in overpass_urls:
        try:
            # Preferred: POST form parameter 'data'
            resp = requests.post(url, data={"data": query}, headers=headers, timeout=30)
            if resp.status_code == 406:
                app.logger.info("Overpass returned 406, retrying with GET and raw POST")
                # try GET with URL-encoded 'data' param
                try:
                    resp = requests.get(url, params={"data": query}, headers=headers, timeout=30)
                except requests.exceptions.RequestException:
                    resp = None

                # if GET didn't succeed or also indicates 406, try raw POST
                if resp is None or resp.status_code == 406:
                    headers_raw = headers.copy()
                    headers_raw["Content-Type"] = "text/plain; charset=utf-8"
                    resp = requests.post(url, data=query.encode("utf-8"), headers=headers_raw, timeout=30)

            resp.raise_for_status()
            resp_elems = resp.json().get("elements", [])
            if resp_elems:
                return resp_elems
            else:
                app.logger.info("Overpass returned empty result from %s, trying next endpoint", url)
                last_exc = None
                continue
        except requests.exceptions.RequestException as e:
            app.logger.warning("Overpass request to %s failed: %s", url, e)
            last_exc = e
            continue
    # if we fall through, try a Photon-based fallback (search common POI keywords)
    app.logger.info("All Overpass endpoints failed, trying Photon POI fallback")

    def photon_search(query_term, limit=5):
        photon_url = "https://photon.komoot.io/api/"
        headers = {"User-Agent": USER_AGENT, "From": os.environ.get("NOMINATIM_EMAIL", "contact@example.com")}
        params = {"q": query_term, "lat": lat, "lon": lon, "limit": limit}
        try:
            r = requests.get(photon_url, params=params, headers=headers, timeout=8)
            r.raise_for_status()
            j = r.json()
            return j.get("features") or []
        except requests.exceptions.RequestException as e:
            app.logger.warning("Photon POI search failed for %s: %s", query_term, e)
            return []

    categories_terms = {
        "stops": ["bus stop", "tram stop", "station", "stop", "bus station", "t-bane", "metro", "subway", "trikk"],
        "shops": ["supermarket", "convenience store", "grocery", "shop", "butikk"],
        "schools": ["school", "skole", "videregående skole", "ungdomsskole"],
        "kindergartens": ["kindergarten", "barnehage", "barnehagen"],
        "post": ["post office", "post box", "posten", "pakke", "post i butikk", "postkontor"],
        "culture": ["library", "bibliotek", "museum", "kino", "cinema", "theater", "theatre", "teater", "deichman"],
        "sports": ["gym", "fitness centre", "stadium", "sports centre", "football stadium", "climbing", "klatrehall", "idrettshall", "treningssenter"],
        "services": ["pharmacy", "bank", "cafe", "restaurant"],
    }

    elements = []
    seen = set()
    for cat, terms in categories_terms.items():
        for term in terms:
            feats = photon_search(term, limit=6)
            for f in feats:
                props = f.get("properties", {})
                geom = f.get("geometry", {})
                coords = geom.get("coordinates") or []
                if not coords or len(coords) < 2:
                    continue
                lon_p, lat_p = coords[0], coords[1]
                # filter out features that are far away (photon can return global matches)
                try:
                    dist_km = haversine(lat, lon, lat_p, lon_p)
                except Exception:
                    dist_km = None
                if dist_km is None or dist_km > (radius / 1000.0) * 1.5:
                    continue
                key = (round(lat_p, 6), round(lon_p, 6), props.get("name"))
                if key in seen:
                    continue
                seen.add(key)
                tags = {}
                # map some photon properties into tags used by collect_poi
                if props.get("osm_key"):
                    tags[props.get("osm_key")] = props.get("osm_value")
                if props.get("name"):
                    tags["name"] = props.get("name")
                # provide a hint category
                tags["_photon_category"] = cat
                elements.append({"lat": lat_p, "lon": lon_p, "tags": tags})

    if elements:
        return elements

    # if still nothing, try Nominatim bounded search as a last resort
    app.logger.info("Photon returned no features; trying Nominatim bounded search fallback")

    def nominatim_search(qterm, limit=6):
        nom_url = "https://nominatim.openstreetmap.org/search"
        email = os.environ.get("NOMINATIM_EMAIL", "contact@example.com")
        headers = {"User-Agent": USER_AGENT, "From": email}
        # compute a rough bounding box from radius (meters -> degrees)
        km = radius / 1000.0
        dlat = km / 111.0
        dlng = km / (111.0 * max(0.01, math.cos(math.radians(lat))))
        left = lon - dlng
        right = lon + dlng
        top = lat + dlat
        bottom = lat - dlat
        params = {"q": qterm, "format": "json", "limit": limit, "viewbox": f"{left},{top},{right},{bottom}", "bounded": 1, "addressdetails": 0, "extratags": 0, "email": email}
        try:
            r = requests.get(nom_url, params=params, headers=headers, timeout=8)
            r.raise_for_status()
            return r.json()
        except requests.exceptions.RequestException as e:
            app.logger.warning("Nominatim POI search failed for %s: %s", qterm, e)
            return []

    elements = []
    seen = set()
    for cat, terms in categories_terms.items():
        for term in terms:
            results = nominatim_search(term, limit=6)
            for res in results:
                try:
                    lat_p = float(res.get("lat"))
                    lon_p = float(res.get("lon"))
                except Exception:
                    continue
                # filter by distance from center
                try:
                    dist_km = haversine(lat, lon, lat_p, lon_p)
                except Exception:
                    dist_km = None
                if dist_km is None or dist_km > (radius / 1000.0) * 1.5:
                    continue
                key = (round(lat_p, 6), round(lon_p, 6), res.get("display_name"))
                if key in seen:
                    continue
                seen.add(key)
                tags = {"name": res.get("display_name")}
                tags["_nominatim_category"] = cat
                elements.append({"lat": lat_p, "lon": lon_p, "tags": tags})

    if elements:
        return elements

    # if still nothing, generate demo POIs (local synthetic placeholders) so the map shows something
    app.logger.info("All remote POI lookups failed; generating demo POIs")
    demo_elements = []
    demo_offsets = [(-0.001, -0.001), (-0.001, 0.001), (0.001, -0.001), (0.001, 0.001), (0.0, 0.001)]
    demo_names = {
        "stops": "Demo Stop",
        "shops": "Demo Shop",
        "schools": "Demo School",
        "services": "Demo Service",
    }
    i = 0
    for cat in ["stops", "shops", "schools", "services"]:
        for off in demo_offsets[:3]:
            lat_p = lat + off[0]
            lon_p = lon + off[1]
            name = f"{demo_names[cat]} {i+1}"
            tags = {"name": name, "_demo": True, "_demo_category": cat}
            demo_elements.append({"lat": lat_p, "lon": lon_p, "tags": tags})
            i += 1
    return demo_elements


def normalize_name(tags):
    return tags.get("name") or tags.get("ref") or tags.get("operator") or tags.get("amenity") or tags.get("shop") or "Unknown"


def categorize_poi(tags):
    if tags.get("highway") == "bus_stop" or tags.get("amenity") == "bus_station" or tags.get("public_transport") in ["platform", "stop_position"] or tags.get("railway") in ["tram_stop", "stop", "station"]:
        return "stops"
    if tags.get("amenity") == "kindergarten":
        return "kindergartens"
    if tags.get("amenity") == "school":
        return "schools"
    if tags.get("amenity") in ["post_office", "post_box"] or tags.get("shop") == "parcel_pickup":
        return "post"
    if tags.get("amenity") == "library" or tags.get("tourism") == "museum" or tags.get("amenity") == "cinema" or tags.get("amenity") == "theatre" or tags.get("leisure") == "arts_centre":
        return "culture"
    if tags.get("leisure") in ["fitness_centre", "sports_centre", "stadium", "dance_studio"] or tags.get("sport") in ["climbing", "football", "soccer"]:
        return "sports"
    if tags.get("shop") in ["supermarket", "convenience"]:
        return "shops"
    if tags.get("_photon_category") in ["schools", "kindergartens", "post", "culture", "sports"]:
        return tags.get("_photon_category")
    if tags.get("_nominatim_category") in ["schools", "kindergartens", "post", "culture", "sports"]:
        return tags.get("_nominatim_category")

    name = (tags.get("name") or "").lower()
    if any(word in name for word in ["skole", "barnehage", "kindergarten"]):
        return "schools" if "skole" in name or "school" in name else "kindergartens"
    if any(word in name for word in ["post", "pakke", "posten"]):
        return "post"
    if any(word in name for word in ["bibliotek", "library", "museum", "kino", "cinema", "teater", "theatre"]):
        return "culture"
    if any(word in name for word in ["gym", "fitness", "idrett", "stadion", "klatre", "trenings", "sport"]):
        return "sports"
    return "services"


def collect_poi(address_lat, address_lon, elements):
    categories = {"stops": [], "schools": [], "kindergartens": [], "shops": [], "post": [], "culture": [], "sports": [], "services": []}
    seen = set()
    for element in elements:
        tags = element.get("tags", {})
        lat = element.get("lat") or element.get("center", {}).get("lat")
        lon = element.get("lon") or element.get("center", {}).get("lon")
        if lat is None or lon is None:
            continue
        # deduplicate by OSM id or rounded coords+name
        elem_id = element.get("id")
        if elem_id:
            key = ("id", elem_id)
        else:
            key = ("xyname", round(lat, 5), round(lon, 5), tags.get("name"))
        if key in seen:
            continue
        seen.add(key)
        route = route_info(address_lat, address_lon, lat, lon)
        if route:
            route_distance_km = route["distance_km"]
            walk_min = route["walk_min"]
        else:
            route_distance_km = round(haversine(address_lat, address_lon, lat, lon), 2)
            walk_min = None
        item = {
            "name": normalize_name(tags),
            "lat": lat,
            "lon": lon,
            "distance_km": route_distance_km,
            "walk_min": walk_min,
            "elevation_gain_m": route.get("elevation_gain_m") if route else None,
            "category": categorize_poi(tags),
            "tags": tags,
        }
        categories[item["category"]].append(item)
    for values in categories.values():
        values.sort(key=lambda item: item["distance_km"])

    # merge nearby stops that represent the same stop in opposite directions
    def merge_close_items(items, max_m=50):
        clusters = []
        for item in items:
            placed = False
            for c in clusters:
                d = haversine(item["lat"], item["lon"], c["lat"], c["lon"]) * 1000.0
                if d <= max_m:
                    c["members"].append(item)
                    # recompute centroid
                    c["lat"] = sum(m["lat"] for m in c["members"]) / len(c["members"])    
                    c["lon"] = sum(m["lon"] for m in c["members"]) / len(c["members"])    
                    c["distance_km"] = min(c["distance_km"], item["distance_km"])    
                    if c.get("walk_min") is None:
                        c["walk_min"] = item.get("walk_min")
                    elif item.get("walk_min") is not None:
                        c["walk_min"] = min(c["walk_min"], item.get("walk_min"))
                    placed = True
                    break
            if not placed:
                clusters.append({"lat": item["lat"], "lon": item["lon"], "members": [item], "name": item["name"], "distance_km": item["distance_km"], "walk_min": item.get("walk_min")})
        merged = []
        for c in clusters:
            merged.append({"name": c["name"], "lat": c["lat"], "lon": c["lon"], "distance_km": round(c["distance_km"], 2), "walk_min": c.get("walk_min"), "category": "stops", "tags": c["members"][0].get("tags", {})})
        return merged

    categories["stops"] = merge_close_items(categories["stops"], max_m=50)
    return categories


@app.route("/", methods=["GET", "POST"])
def index():
    error = None
    results = None
    map_data = None
    map_html = None
    address = None

    if request.method == "POST":
        address = request.form.get("address", "").strip()
        if not address:
            error = "Please enter an address."
        else:
            try:
                coords = geocode(address)
            except Exception as e:
                error = str(e)
                coords = None

            if not coords:
                if not error:
                    error = "Address not found. Please try a more precise address."
            else:
                lat, lon = coords
                try:
                    elements = get_poi(lat, lon)
                except Exception as e:
                    app.logger.warning("get_poi failed: %s", e)
                    error = "Could not retrieve nearby points of interest (Overpass API error). Map is still shown for the searched location. Please try again later."
                    elements = []
                categories = collect_poi(lat, lon, elements)
                results = {
                    "address": address,
                    "lat": lat,
                    "lon": lon,
                    "stops": categories["stops"][:3],
                    "schools": categories["schools"][:3],
                    "kindergartens": categories["kindergartens"][:3],
                    "shops": categories["shops"][:3],
                    "post": categories["post"][:3],
                    "culture": categories["culture"][:3],
                    "sports": categories["sports"][:3],
                    "services": categories["services"][:3],
                }
                pois = results["stops"] + results["schools"] + results["kindergartens"] + results["shops"] + results["post"] + results["culture"] + results["sports"] + results["services"]
                map_data = {
                    "address": address,
                    "lat": lat,
                    "lon": lon,
                    "pois": pois,
                }
                try:
                    # build a folium (leaflet) map on the server side and pass HTML to template
                    m = folium.Map(location=[lat, lon], zoom_start=15)
                    folium.CircleMarker([lat, lon], radius=7, color="black", fill=True, fill_color="black", fill_opacity=0.9, popup=f"{address}").add_to(m)
                    for poi in pois:
                        color = COLOR_MAP.get(poi.get("category"), "gray")
                        display_distance = poi.get("distance_km") if poi.get("distance_km") is not None else "N/A"
                        display_walk = poi.get("walk_min") if poi.get("walk_min") is not None else "N/A"
                        incline = poi.get("elevation_gain_m")
                        incline_text = f"<br>Incline gain: {int(incline)} m" if incline is not None and incline > 0 else ""
                        popup_html = f"<strong>{poi['name']}</strong><br>{poi['category']}<br>Distance: {display_distance} km<br>Walk: {display_walk} min{incline_text}"
                        folium.CircleMarker([poi["lat"], poi["lon"]], radius=6, color=color, fill=True, fill_color=color, fill_opacity=0.9, popup=popup_html).add_to(m)
                    map_html = m._repr_html_()
                except Exception as e:
                    app.logger.warning("Folium map build failed: %s", e)
                    map_html = None

    return render_template("index.html", error=error, results=results, map_data=map_data, map_html=map_html, address=address)


if __name__ == "__main__":
    app.run(debug=True)
```


![Address-Based Neighborhood Analyzer](images/nabolagsutforsker.png)
