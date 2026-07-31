import 'package:flutter/material.dart';

enum LightNeed { directLight, strongIndirect, weakIndirect, shade }

class LightMeta {
  final IconData icon;
  final String tag;

  const LightMeta(this.icon, this.tag);
}

LightMeta lightMeta(LightNeed light) {
  switch (light) {
    case LightNeed.directLight:
      return const LightMeta(Icons.wb_sunny_outlined, "Soare direct");
    case LightNeed.strongIndirect:
      return const LightMeta(Icons.wb_cloudy_outlined, "Lumină puternică");
    case LightNeed.weakIndirect:
      return const LightMeta(Icons.cloud_outlined, "Lumină slabă");
    case LightNeed.shade:
      return const LightMeta(Icons.nightlight_outlined, "Umbră");
  }
}

String lightLabelRo(LightNeed light) {
  switch (light) {
    case LightNeed.directLight:
      return "Lumină directă, câteva ore de soare pe zi";
    case LightNeed.strongIndirect:
      return "Lumină indirectă puternică, lângă o fereastră";
    case LightNeed.weakIndirect:
      return "Lumină indirectă slabă, tolerează și colțuri mai umbrite";
    case LightNeed.shade:
      return "Umbră sau lumină foarte slabă";
  }
}

String lightNeedToDb(LightNeed light) => light.name;

LightNeed lightNeedFromDb(String value) {
  return LightNeed.values.firstWhere(
    (l) => l.name == value,
    orElse: () => LightNeed.strongIndirect,
  );
}

class CareInfo {
  final String commonNameRo;
  final int wateringDays;
  final LightNeed light;
  final bool misting;
  final bool toxicToPets;
  final List<String> tips;

  const CareInfo({
    required this.commonNameRo,
    required this.wateringDays,
    required this.light,
    required this.misting,
    required this.toxicToPets,
    required this.tips,
  });

  CareInfo copyWith({String? commonNameRo}) => CareInfo(
        commonNameRo: commonNameRo ?? this.commonNameRo,
        wateringDays: wateringDays,
        light: light,
        misting: misting,
        toxicToPets: toxicToPets,
        tips: tips,
      );
}

// Cheia e numele știintific (gen + specie) în minuscule, așa cum apare în modelul de recunoaștere.
// Pentru specii fără intrare exactă, se caută o potrivire după gen (primul cuvânt).
final Map<String, CareInfo> kCareDb = {
  "epipremnum aureum": const CareInfo(
    commonNameRo: "Pothos (Epipremnum aureum)",
    wateringDays: 7,
    light: LightNeed.weakIndirect,
    misting: false,
    toxicToPets: true,
    tips: [
      "Udă când primii 3-4 cm de sol sunt uscați.",
      "Foarte tolerantă, ideală pentru începători.",
      "Taie lăstarii lungi pentru o formă mai stufoasă.",
    ],
  ),
  "monstera deliciosa": const CareInfo(
    commonNameRo: "Monstera (Monstera deliciosa)",
    wateringDays: 7,
    light: LightNeed.strongIndirect,
    misting: true,
    toxicToPets: true,
    tips: [
      "Lasă solul să se usuce la suprafață între udări.",
      "Are nevoie de un suport (moss pole) pe măsură ce crește.",
      "Șterge frunzele de praf pentru fotosinteză mai bună.",
    ],
  ),
  "sansevieria trifasciata": const CareInfo(
    commonNameRo: "Limba soacrei (Sansevieria)",
    wateringDays: 18,
    light: LightNeed.weakIndirect,
    misting: false,
    toxicToPets: true,
    tips: [
      "Foarte rezistentă la neglijare; udarea excesivă e principalul risc.",
      "Lasă solul complet uscat între udări.",
      "Tolerează lumină slabă și aer uscat.",
    ],
  ),
  "dracaena trifasciata": const CareInfo(
    commonNameRo: "Limba soacrei (Dracaena trifasciata)",
    wateringDays: 18,
    light: LightNeed.weakIndirect,
    misting: false,
    toxicToPets: true,
    tips: ["Lasă solul complet uscat între udări.", "Foarte tolerantă la neglijare."],
  ),
  "ficus elastica": const CareInfo(
    commonNameRo: "Ficus de cauciuc (Ficus elastica)",
    wateringDays: 9,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicToPets: true,
    tips: ["Udă moderat, evită udarea excesivă.", "Șterge frunzele lucioase periodic."],
  ),
  "ficus lyrata": const CareInfo(
    commonNameRo: "Ficus cu frunza de vioară (Ficus lyrata)",
    wateringDays: 9,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicToPets: true,
    tips: ["Sensibilă la schimbări bruște de locație.", "Evită curenții de aer rece."],
  ),
  "ficus benjamina": const CareInfo(
    commonNameRo: "Ficus benjamina",
    wateringDays: 8,
    light: LightNeed.strongIndirect,
    misting: true,
    toxicToPets: true,
    tips: ["Nu-i place să fie mutat des.", "Pierde frunze dacă e stresat de curent/temperatură."],
  ),
  "chlorophytum comosum": const CareInfo(
    commonNameRo: "Clorofit (Chlorophytum comosum)",
    wateringDays: 6,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicToPets: false,
    tips: ["Foarte ușor de îngrijit.", "Produce plantule mici pe care le poți replanta."],
  ),
  "spathiphyllum wallisii": const CareInfo(
    commonNameRo: "Crin de pace (Spathiphyllum)",
    wateringDays: 6,
    light: LightNeed.weakIndirect,
    misting: true,
    toxicToPets: true,
    tips: ["Frunzele lăsate în jos = semn clar că are nevoie de apă.", "Preferă umiditate mai mare."],
  ),
  "zamioculcas zamiifolia": const CareInfo(
    commonNameRo: "ZZ Plant (Zamioculcas zamiifolia)",
    wateringDays: 18,
    light: LightNeed.weakIndirect,
    misting: false,
    toxicToPets: true,
    tips: ["Rezistentă la secetă; udă rar.", "Evită udarea excesivă, are rizomi care rețin apă."],
  ),
  "aloe vera": const CareInfo(
    commonNameRo: "Aloe Vera",
    wateringDays: 16,
    light: LightNeed.directLight,
    misting: false,
    toxicToPets: true,
    tips: ["Sol bine drenat, tip cactus/suculente.", "Udă abundent, apoi lasă solul să se usuce complet."],
  ),
  "crassula ovata": const CareInfo(
    commonNameRo: "Copăcelul norocului (Crassula ovata)",
    wateringDays: 14,
    light: LightNeed.directLight,
    misting: false,
    toxicToPets: true,
    tips: ["Suculentă, sensibilă la udare excesivă.", "Are nevoie de multă lumină pentru a nu se \"întinde\"."],
  ),
  "philodendron hederaceum": const CareInfo(
    commonNameRo: "Philodendron agățător",
    wateringDays: 7,
    light: LightNeed.weakIndirect,
    misting: false,
    toxicToPets: true,
    tips: ["Udă când solul e uscat la suprafață.", "Crește bine agățat sau pe suport."],
  ),
  "dracaena fragrans": const CareInfo(
    commonNameRo: "Dracaena fragrans",
    wateringDays: 10,
    light: LightNeed.weakIndirect,
    misting: false,
    toxicToPets: true,
    tips: ["Sensibilă la clorul din apa de la robinet; folosește apă lăsată la decantat."],
  ),
  "peperomia obtusifolia": const CareInfo(
    commonNameRo: "Peperomia",
    wateringDays: 9,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicToPets: false,
    tips: ["Frunzele groase rețin apă, nu uda prea des."],
  ),
  "hedera helix": const CareInfo(
    commonNameRo: "Iederă (Hedera helix)",
    wateringDays: 6,
    light: LightNeed.strongIndirect,
    misting: true,
    toxicToPets: true,
    tips: ["Preferă aer mai umed și răcoros.", "Nu lăsa solul complet uscat perioade lungi."],
  ),
  "aglaonema commutatum": const CareInfo(
    commonNameRo: "Aglaonema",
    wateringDays: 8,
    light: LightNeed.weakIndirect,
    misting: false,
    toxicToPets: true,
    tips: ["Tolerantă la lumină slabă.", "Evită curenții reci."],
  ),
  "anthurium andraeanum": const CareInfo(
    commonNameRo: "Anthurium",
    wateringDays: 6,
    light: LightNeed.strongIndirect,
    misting: true,
    toxicToPets: true,
    tips: ["Preferă umiditate ridicată.", "Udă când primii cm de sol sunt uscați."],
  ),
  "tradescantia zebrina": const CareInfo(
    commonNameRo: "Tradescantia zebrina",
    wateringDays: 5,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicToPets: true,
    tips: ["Crește repede, poate fi tăiată des pentru formă stufoasă."],
  ),
  "nephrolepis exaltata": const CareInfo(
    commonNameRo: "Ferigă Boston (Nephrolepis exaltata)",
    wateringDays: 4,
    light: LightNeed.weakIndirect,
    misting: true,
    toxicToPets: false,
    tips: ["Preferă sol permanent reavăn și umiditate ridicată."],
  ),
  "chamaedorea elegans": const CareInfo(
    commonNameRo: "Palmier pitic (Chamaedorea elegans)",
    wateringDays: 8,
    light: LightNeed.weakIndirect,
    misting: true,
    toxicToPets: false,
    tips: ["Sensibil la exces de apă și săruri minerale."],
  ),
  "beaucarnea recurvata": const CareInfo(
    commonNameRo: "Piciorul elefantului (Beaucarnea recurvata)",
    wateringDays: 16,
    light: LightNeed.directLight,
    misting: false,
    toxicToPets: false,
    tips: ["Trunchiul stochează apă; udă rar."],
  ),
  "pilea peperomioides": const CareInfo(
    commonNameRo: "Pilea peperomioides",
    wateringDays: 7,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicToPets: false,
    tips: ["Rotește planta periodic pentru creștere uniformă."],
  ),
  "maranta leuconeura": const CareInfo(
    commonNameRo: "Planta rugăciunii (Maranta leuconeura)",
    wateringDays: 5,
    light: LightNeed.weakIndirect,
    misting: true,
    toxicToPets: false,
    tips: ["Frunzele se ridică seara.", "Preferă umiditate mai mare și sol constant reavăn."],
  ),
  "syngonium podophyllum": const CareInfo(
    commonNameRo: "Syngonium",
    wateringDays: 7,
    light: LightNeed.weakIndirect,
    misting: false,
    toxicToPets: true,
    tips: ["Ușor de îngrijit, crește bine și agățat."],
  ),
  "strelitzia reginae": const CareInfo(
    commonNameRo: "Pasărea paradisului (Strelitzia reginae)",
    wateringDays: 8,
    light: LightNeed.directLight,
    misting: false,
    toxicToPets: true,
    tips: ["Are nevoie de multă lumină pentru a înflori."],
  ),
  "codiaeum variegatum": const CareInfo(
    commonNameRo: "Croton (Codiaeum variegatum)",
    wateringDays: 6,
    light: LightNeed.directLight,
    misting: true,
    toxicToPets: true,
    tips: ["Culorile frunzelor depind de cantitatea de lumină."],
  ),
  "fittonia albivenis": const CareInfo(
    commonNameRo: "Fittonia (mozaic)",
    wateringDays: 4,
    light: LightNeed.weakIndirect,
    misting: true,
    toxicToPets: false,
    tips: ["Se ofilește vizibil când are nevoie de apă, dar își revine repede după udare."],
  ),
  "hoya carnosa": const CareInfo(
    commonNameRo: "Hoya carnosa",
    wateringDays: 12,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicToPets: false,
    tips: ["Lasă solul să se usuce bine între udări.", "Nu muta florile ofilite, poate înflori din nou din același loc."],
  ),
  "euphorbia trigona": const CareInfo(
    commonNameRo: "Euphorbia trigona",
    wateringDays: 14,
    light: LightNeed.directLight,
    misting: false,
    toxicToPets: true,
    tips: ["Sucul e iritant pentru piele; poartă mănuși la manipulare."],
  ),
  "schlumbergera truncata": const CareInfo(
    commonNameRo: "Cactus de Crăciun (Schlumbergera)",
    wateringDays: 8,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicToPets: false,
    tips: ["Are nevoie de nopți mai lungi/răcoroase toamna pentru a înflori."],
  ),
  "cyclamen persicum": const CareInfo(
    commonNameRo: "Ciclamen (Cyclamen persicum)",
    wateringDays: 5,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicToPets: true,
    tips: ["Udă de la bază (în farfurioară) ca să eviți putrezirea tuberculului."],
  ),
  "lavandula angustifolia": const CareInfo(
    commonNameRo: "Lavandă",
    wateringDays: 9,
    light: LightNeed.directLight,
    misting: false,
    toxicToPets: false,
    tips: ["Sol bine drenat, evită excesul de apă și umezeala la rădăcină."],
  ),
  "rosmarinus officinalis": const CareInfo(
    commonNameRo: "Rozmarin",
    wateringDays: 7,
    light: LightNeed.directLight,
    misting: false,
    toxicToPets: false,
    tips: ["Preferă să se usuce ușor între udări, nu tolerează udarea excesivă."],
  ),
  "ocimum basilicum": const CareInfo(
    commonNameRo: "Busuioc",
    wateringDays: 3,
    light: LightNeed.directLight,
    misting: false,
    toxicToPets: false,
    tips: ["Menține solul constant reavăn.", "Ciupește vârfurile pentru creștere stufoasă."],
  ),
  "mentha spicata": const CareInfo(
    commonNameRo: "Mentă",
    wateringDays: 4,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicToPets: false,
    tips: ["Îi place solul umed constant.", "Crește foarte invaziv, bine să fie într-un ghiveci separat."],
  ),
  "citrus limon": const CareInfo(
    commonNameRo: "Lămâi (Citrus limon)",
    wateringDays: 6,
    light: LightNeed.directLight,
    misting: false,
    toxicToPets: true,
    tips: ["Are nevoie de multă lumină directă și îngrășământ pentru citrice."],
  ),
  "solanum lycopersicum": const CareInfo(
    commonNameRo: "Roșie (Solanum lycopersicum)",
    wateringDays: 3,
    light: LightNeed.directLight,
    misting: false,
    toxicToPets: true,
    tips: ["Udare constantă și regulată, evită udarea neregulată (crapă fructele)."],
  ),
  "rosa chinensis": const CareInfo(
    commonNameRo: "Trandafir",
    wateringDays: 4,
    light: LightNeed.directLight,
    misting: false,
    toxicToPets: false,
    tips: ["Udă la bază, evită udarea frunzelor pentru a preveni ciupercile."],
  ),
  "opuntia ficus-indica": const CareInfo(
    commonNameRo: "Cactus (Opuntia)",
    wateringDays: 20,
    light: LightNeed.directLight,
    misting: false,
    toxicToPets: false,
    tips: ["Udă rar, doar când solul e complet uscat.", "Sol special pentru cactuși/suculente."],
  ),
  "echeveria elegans": const CareInfo(
    commonNameRo: "Echeveria",
    wateringDays: 14,
    light: LightNeed.directLight,
    misting: false,
    toxicToPets: false,
    tips: ["Udă de la bază, evită să uzi frunzele rozetei."],
  ),
  "calathea orbifolia": const CareInfo(
    commonNameRo: "Calathea",
    wateringDays: 5,
    light: LightNeed.weakIndirect,
    misting: true,
    toxicToPets: false,
    tips: [
      "Foarte sensibilă la apa cu clor/săruri; folosește apă filtrată sau decantată.",
      "Preferă umiditate ridicată.",
    ],
  ),
  "begonia rex": const CareInfo(
    commonNameRo: "Begonia Rex",
    wateringDays: 6,
    light: LightNeed.weakIndirect,
    misting: false,
    toxicToPets: true,
    tips: ["Evită udarea frunzelor, favorizează mucegaiul."],
  ),
  "alocasia amazonica": const CareInfo(
    commonNameRo: "Alocasia",
    wateringDays: 6,
    light: LightNeed.strongIndirect,
    misting: true,
    toxicToPets: true,
    tips: ["Preferă umiditate mare și sol constant reavăn, dar bine drenat."],
  ),
  "yucca elephantipes": const CareInfo(
    commonNameRo: "Yucca",
    wateringDays: 14,
    light: LightNeed.directLight,
    misting: false,
    toxicToPets: true,
    tips: ["Rezistentă la secetă, udă rar și abundent."],
  ),
  "ceropegia woodii": const CareInfo(
    commonNameRo: "Lanțul inimilor (Ceropegia woodii)",
    wateringDays: 12,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicToPets: false,
    tips: ["Are tuberculi care rețin apă; nu uda excesiv."],
  ),
  "dracaena marginata": const CareInfo(
    commonNameRo: "Dracaena marginata",
    wateringDays: 10,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicToPets: true,
    tips: ["Udă doar când primii 5 cm de sol sunt uscați.", "Sensibilă la excesul de clor/fluor din apa de la robinet."],
  ),
  "dieffenbachia seguine": const CareInfo(
    commonNameRo: "Dieffenbachia",
    wateringDays: 7,
    light: LightNeed.weakIndirect,
    misting: false,
    toxicToPets: true,
    tips: ["Seva este iritantă; poartă mănuși la tăiere.", "Tolerează lumină mai slabă, dar crește mai încet."],
  ),
  "schefflera arboricola": const CareInfo(
    commonNameRo: "Schefflera (Copacul umbrelă)",
    wateringDays: 7,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicToPets: true,
    tips: ["Lasă solul să se usuce la suprafață între udări.", "Rotește planta periodic spre lumină pentru creștere uniformă."],
  ),
  "aspidistra elatior": const CareInfo(
    commonNameRo: "Planta de fontă (Aspidistra elatior)",
    wateringDays: 10,
    light: LightNeed.shade,
    misting: false,
    toxicToPets: false,
    tips: ["Extrem de tolerantă la neglijare și lumină slabă.", "Evită udarea excesivă; solul poate rămâne ușor uscat."],
  ),
  "monstera adansonii": const CareInfo(
    commonNameRo: "Monstera adansonii (Frunza de brânză elvețiană)",
    wateringDays: 7,
    light: LightNeed.strongIndirect,
    misting: true,
    toxicToPets: true,
    tips: ["Preferă un suport pe care să se agațe.", "Lasă solul să se usuce la suprafață între udări."],
  ),
  "rhaphidophora tetrasperma": const CareInfo(
    commonNameRo: "Mini Monstera (Rhaphidophora tetrasperma)",
    wateringDays: 7,
    light: LightNeed.strongIndirect,
    misting: true,
    toxicToPets: true,
    tips: ["Crește repede cu un suport tip moss pole.", "Udă când primii 3-4 cm de sol sunt uscați."],
  ),
  "scindapsus pictus": const CareInfo(
    commonNameRo: "Pothos satinat (Scindapsus pictus)",
    wateringDays: 8,
    light: LightNeed.weakIndirect,
    misting: false,
    toxicToPets: true,
    tips: ["Tolerează lumină mai slabă decât alte pothos.", "Lasă solul să se usuce bine între udări."],
  ),
  "pachira aquatica": const CareInfo(
    commonNameRo: "Copacul banilor (Pachira aquatica)",
    wateringDays: 9,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicToPets: false,
    tips: ["Sensibil la udarea excesivă; lasă solul să se usuce parțial.", "Preferă umiditate moderată și fără curenți reci."],
  ),
  "platycerium bifurcatum": const CareInfo(
    commonNameRo: "Ferigă coarne de cerb (Platycerium bifurcatum)",
    wateringDays: 7,
    light: LightNeed.strongIndirect,
    misting: true,
    toxicToPets: false,
    tips: ["Preferă montare pe suport sau ghiveci suspendat.", "Udă prin înmuiere periodică, nu direct pe frunze."],
  ),
  "asplenium nidus": const CareInfo(
    commonNameRo: "Ferigă cuib de pasăre (Asplenium nidus)",
    wateringDays: 6,
    light: LightNeed.weakIndirect,
    misting: true,
    toxicToPets: false,
    tips: ["Preferă umiditate ridicată și sol constant reavăn.", "Nu atinge frunza centrală nouă, e fragilă."],
  ),
  "senecio rowleyanus": const CareInfo(
    commonNameRo: "Șirag de perle (Senecio rowleyanus)",
    wateringDays: 14,
    light: LightNeed.directLight,
    misting: false,
    toxicToPets: true,
    tips: ["Lasă solul să se usuce complet între udări.", "Evită udarea pe frunze (bobițe), poate duce la putrezire."],
  ),
  "kalanchoe blossfeldiana": const CareInfo(
    commonNameRo: "Kalanchoe",
    wateringDays: 9,
    light: LightNeed.directLight,
    misting: false,
    toxicToPets: true,
    tips: ["Elimină florile ofilite pentru înflorire continuă.", "Udă moderat; sensibilă la exces de apă."],
  ),
  "haworthia fasciata": const CareInfo(
    commonNameRo: "Haworthia zebra (Haworthia fasciata)",
    wateringDays: 16,
    light: LightNeed.directLight,
    misting: false,
    toxicToPets: false,
    tips: ["Sol special pentru cactuși/suculente, bine drenat.", "Udă abundent, apoi lasă solul complet uscat."],
  ),
  "euphorbia milii": const CareInfo(
    commonNameRo: "Coroana de spini (Euphorbia milii)",
    wateringDays: 10,
    light: LightNeed.directLight,
    misting: false,
    toxicToPets: true,
    tips: ["Seva este iritantă pentru piele; poartă mănuși.", "Lasă solul să se usuce bine între udări."],
  ),
  "ficus pumila": const CareInfo(
    commonNameRo: "Ficus pitic agățător (Ficus pumila)",
    wateringDays: 6,
    light: LightNeed.weakIndirect,
    misting: true,
    toxicToPets: true,
    tips: ["Preferă umiditate mai mare și sol constant reavăn.", "Poate fi tuns pentru a-și controla creșterea agățătoare."],
  ),
};

const CareInfo kGenericFallbackCare = CareInfo(
  commonNameRo: "Plantă neidentificată exact în baza de îngrijire",
  wateringDays: 7,
  light: LightNeed.strongIndirect,
  misting: false,
  toxicToPets: false,
  tips: [
    "Verifică solul cu degetul: udă când primii 2-3 cm sunt uscați.",
    "Evită apa stătută în farfurioară.",
    "Așază planta într-o zonă cu lumină indirectă, ferită de soare direct puternic la prânz.",
    "Aceste informații sunt generale — ajustează în funcție de cum reacționează planta ta.",
  ],
);

CareInfo getCareInfo(String scientificName) {
  final key = scientificName.trim().toLowerCase();
  final exact = kCareDb[key];
  if (exact != null) return exact;

  final genus = key.split(" ").first;
  for (final entry in kCareDb.entries) {
    if (entry.key.startsWith("$genus ")) {
      return entry.value.copyWith(commonNameRo: "${entry.value.commonNameRo} (specie înrudită)");
    }
  }

  return kGenericFallbackCare;
}
