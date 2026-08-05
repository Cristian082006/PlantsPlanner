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

/// Adjusts a species' base watering interval using the current month
/// (growth vs. dormant season) and, when known, the outdoor temperature —
/// plants dry out faster and need water more often in hot summer weather,
/// and less often during the cold/dormant months.
int adjustedWateringDays({
  required int baseDays,
  double? outdoorTempC,
  DateTime? now,
}) {
  final date = now ?? DateTime.now();
  final month = date.month;

  double seasonFactor;
  if (month == 12 || month <= 2) {
    seasonFactor = 1.3; // iarnă — repaus vegetativ
  } else if (month <= 5) {
    seasonFactor = 1.0; // primăvară
  } else if (month <= 8) {
    seasonFactor = 0.85; // vară
  } else {
    seasonFactor = 1.1; // toamnă
  }

  var tempFactor = 1.0;
  if (outdoorTempC != null) {
    if (outdoorTempC > 22) {
      tempFactor = 1.0 - ((outdoorTempC - 22).clamp(0, 20) * 0.02);
    } else if (outdoorTempC < 18) {
      tempFactor = 1.0 + ((18 - outdoorTempC).clamp(0, 20) * 0.02);
    }
    tempFactor = tempFactor.clamp(0.6, 1.5);
  }

  final adjusted = (baseDays * seasonFactor * tempFactor).round();
  return adjusted.clamp(1, baseDays * 3);
}

const List<String> kCommonRooms = [
  'Living',
  'Dormitor',
  'Bucătărie',
  'Baie',
  'Birou',
  'Balcon',
  'Hol',
];

IconData reminderTypeIcon(String type) {
  switch (type) {
    case 'udare':
      return Icons.water_drop_outlined;
    case 'pulverizare':
      return Icons.water_outlined;
    case 'fertilizare':
      return Icons.eco_outlined;
    case 'taiere':
      return Icons.content_cut;
    default:
      return Icons.water_drop_outlined;
  }
}

// Nu avem date curate per specie pentru tăiere/pliviit, așa că folosim un
// interval general recomandat (trimestrial) pentru majoritatea plantelor
// de apartament.
const int kPruningIntervalDays = 90;

String lightNeedToDb(LightNeed light) => light.name;

LightNeed lightNeedFromDb(String value) {
  return LightNeed.values.firstWhere(
    (l) => l.name == value,
    orElse: () => LightNeed.strongIndirect,
  );
}

/// Nivel de toxicitate pentru animale de companie, clasificat din descrierea
/// simptomelor pe paginile dedicate ASPCA (aspca.org/pet-care/aspca-poison-control/toxic-and-non-toxic-plants)
/// — ASPCA nu publică un scor numeric, doar text liber per plantă, așa că
/// gradul e derivat: `severe` = risc cardiac/neurologic documentat (glicozide
/// cardiace, la ingestie mare), `moderate` = iritație orală/GI clară
/// (vărsături, salivație, sevă iritantă), `mild` = disconfort ușor, tranzitoriu.
enum ToxicityLevel { none, mild, moderate, severe }

String toxicityLevelLabelRo(ToxicityLevel level) {
  switch (level) {
    case ToxicityLevel.none:
      return 'Netoxică';
    case ToxicityLevel.mild:
      return 'Toxicitate ușoară';
    case ToxicityLevel.moderate:
      return 'Toxicitate moderată';
    case ToxicityLevel.severe:
      return 'Toxicitate severă';
  }
}

class CareInfo {
  final String commonNameRo;
  final int wateringDays;
  final LightNeed light;
  final bool misting;
  final ToxicityLevel toxicityLevel;
  final List<String> tips;

  const CareInfo({
    required this.commonNameRo,
    required this.wateringDays,
    required this.light,
    required this.misting,
    required this.toxicityLevel,
    required this.tips,
  });

  bool get toxicToPets => toxicityLevel != ToxicityLevel.none;

  // Nu avem date curate per specie pentru fertilizare, așa că estimăm din
  // ritmul de udare: plantele udate rar (succulente, sansevieria) au nevoie
  // și de fertilizare mai rară decât cele tropicale udate des.
  int get fertilizingDays => wateringDays >= 14 ? 60 : 30;

  CareInfo copyWith({String? commonNameRo}) => CareInfo(
    commonNameRo: commonNameRo ?? this.commonNameRo,
    wateringDays: wateringDays,
    light: light,
    misting: misting,
    toxicityLevel: toxicityLevel,
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
    toxicityLevel: ToxicityLevel.moderate,
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
    toxicityLevel: ToxicityLevel.moderate,
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
    toxicityLevel: ToxicityLevel.moderate,
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
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Lasă solul complet uscat între udări.",
      "Foarte tolerantă la neglijare.",
    ],
  ),
  "ficus elastica": const CareInfo(
    commonNameRo: "Ficus de cauciuc (Ficus elastica)",
    wateringDays: 9,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Udă moderat, evită udarea excesivă.",
      "Șterge frunzele lucioase periodic.",
    ],
  ),
  "ficus lyrata": const CareInfo(
    commonNameRo: "Ficus cu frunza de vioară (Ficus lyrata)",
    wateringDays: 9,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Sensibilă la schimbări bruște de locație.",
      "Evită curenții de aer rece.",
    ],
  ),
  "ficus benjamina": const CareInfo(
    commonNameRo: "Ficus benjamina",
    wateringDays: 8,
    light: LightNeed.strongIndirect,
    misting: true,
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Nu-i place să fie mutat des.",
      "Pierde frunze dacă e stresat de curent/temperatură.",
    ],
  ),
  "chlorophytum comosum": const CareInfo(
    commonNameRo: "Clorofit (Chlorophytum comosum)",
    wateringDays: 6,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Foarte ușor de îngrijit.",
      "Produce plantule mici pe care le poți replanta.",
    ],
  ),
  "spathiphyllum wallisii": const CareInfo(
    commonNameRo: "Crin de pace (Spathiphyllum)",
    wateringDays: 6,
    light: LightNeed.weakIndirect,
    misting: true,
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Frunzele lăsate în jos = semn clar că are nevoie de apă.",
      "Preferă umiditate mai mare.",
    ],
  ),
  "zamioculcas zamiifolia": const CareInfo(
    commonNameRo: "ZZ Plant (Zamioculcas zamiifolia)",
    wateringDays: 18,
    light: LightNeed.weakIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Rezistentă la secetă; udă rar.",
      "Evită udarea excesivă, are rizomi care rețin apă.",
    ],
  ),
  "aloe vera": const CareInfo(
    commonNameRo: "Aloe Vera",
    wateringDays: 16,
    light: LightNeed.directLight,
    misting: false,
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Sol bine drenat, tip cactus/suculente.",
      "Udă abundent, apoi lasă solul să se usuce complet.",
    ],
  ),
  "crassula ovata": const CareInfo(
    commonNameRo: "Copăcelul norocului (Crassula ovata)",
    wateringDays: 14,
    light: LightNeed.directLight,
    misting: false,
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Suculentă, sensibilă la udare excesivă.",
      "Are nevoie de multă lumină pentru a nu se \"întinde\".",
    ],
  ),
  "philodendron hederaceum": const CareInfo(
    commonNameRo: "Philodendron agățător",
    wateringDays: 7,
    light: LightNeed.weakIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Udă când solul e uscat la suprafață.",
      "Crește bine agățat sau pe suport.",
    ],
  ),
  "dracaena fragrans": const CareInfo(
    commonNameRo: "Dracaena fragrans",
    wateringDays: 10,
    light: LightNeed.weakIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Sensibilă la clorul din apa de la robinet; folosește apă lăsată la decantat.",
    ],
  ),
  "peperomia obtusifolia": const CareInfo(
    commonNameRo: "Peperomia",
    wateringDays: 9,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.none,
    tips: ["Frunzele groase rețin apă, nu uda prea des."],
  ),
  "hedera helix": const CareInfo(
    commonNameRo: "Iederă (Hedera helix)",
    wateringDays: 6,
    light: LightNeed.strongIndirect,
    misting: true,
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Preferă aer mai umed și răcoros.",
      "Nu lăsa solul complet uscat perioade lungi.",
    ],
  ),
  "aglaonema commutatum": const CareInfo(
    commonNameRo: "Aglaonema",
    wateringDays: 8,
    light: LightNeed.weakIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.moderate,
    tips: ["Tolerantă la lumină slabă.", "Evită curenții reci."],
  ),
  "anthurium andraeanum": const CareInfo(
    commonNameRo: "Anthurium",
    wateringDays: 6,
    light: LightNeed.strongIndirect,
    misting: true,
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Preferă umiditate ridicată.",
      "Udă când primii cm de sol sunt uscați.",
    ],
  ),
  "tradescantia zebrina": const CareInfo(
    commonNameRo: "Tradescantia zebrina",
    wateringDays: 5,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.mild,
    tips: ["Crește repede, poate fi tăiată des pentru formă stufoasă."],
  ),
  "nephrolepis exaltata": const CareInfo(
    commonNameRo: "Ferigă Boston (Nephrolepis exaltata)",
    wateringDays: 4,
    light: LightNeed.weakIndirect,
    misting: true,
    toxicityLevel: ToxicityLevel.none,
    tips: ["Preferă sol permanent reavăn și umiditate ridicată."],
  ),
  "chamaedorea elegans": const CareInfo(
    commonNameRo: "Palmier pitic (Chamaedorea elegans)",
    wateringDays: 8,
    light: LightNeed.weakIndirect,
    misting: true,
    toxicityLevel: ToxicityLevel.none,
    tips: ["Sensibil la exces de apă și săruri minerale."],
  ),
  "beaucarnea recurvata": const CareInfo(
    commonNameRo: "Piciorul elefantului (Beaucarnea recurvata)",
    wateringDays: 16,
    light: LightNeed.directLight,
    misting: false,
    toxicityLevel: ToxicityLevel.none,
    tips: ["Trunchiul stochează apă; udă rar."],
  ),
  "pilea peperomioides": const CareInfo(
    commonNameRo: "Pilea peperomioides",
    wateringDays: 7,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.none,
    tips: ["Rotește planta periodic pentru creștere uniformă."],
  ),
  "maranta leuconeura": const CareInfo(
    commonNameRo: "Planta rugăciunii (Maranta leuconeura)",
    wateringDays: 5,
    light: LightNeed.weakIndirect,
    misting: true,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Frunzele se ridică seara.",
      "Preferă umiditate mai mare și sol constant reavăn.",
    ],
  ),
  "syngonium podophyllum": const CareInfo(
    commonNameRo: "Syngonium",
    wateringDays: 7,
    light: LightNeed.weakIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.moderate,
    tips: ["Ușor de îngrijit, crește bine și agățat."],
  ),
  "strelitzia reginae": const CareInfo(
    commonNameRo: "Pasărea paradisului (Strelitzia reginae)",
    wateringDays: 8,
    light: LightNeed.directLight,
    misting: false,
    toxicityLevel: ToxicityLevel.mild,
    tips: ["Are nevoie de multă lumină pentru a înflori."],
  ),
  "codiaeum variegatum": const CareInfo(
    commonNameRo: "Croton (Codiaeum variegatum)",
    wateringDays: 6,
    light: LightNeed.directLight,
    misting: true,
    toxicityLevel: ToxicityLevel.moderate,
    tips: ["Culorile frunzelor depind de cantitatea de lumină."],
  ),
  "fittonia albivenis": const CareInfo(
    commonNameRo: "Fittonia (mozaic)",
    wateringDays: 4,
    light: LightNeed.weakIndirect,
    misting: true,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Se ofilește vizibil când are nevoie de apă, dar își revine repede după udare.",
    ],
  ),
  "hoya carnosa": const CareInfo(
    commonNameRo: "Hoya carnosa",
    wateringDays: 12,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Lasă solul să se usuce bine între udări.",
      "Nu muta florile ofilite, poate înflori din nou din același loc.",
    ],
  ),
  "euphorbia trigona": const CareInfo(
    commonNameRo: "Euphorbia trigona",
    wateringDays: 14,
    light: LightNeed.directLight,
    misting: false,
    toxicityLevel: ToxicityLevel.moderate,
    tips: ["Sucul e iritant pentru piele; poartă mănuși la manipulare."],
  ),
  "schlumbergera truncata": const CareInfo(
    commonNameRo: "Cactus de Crăciun (Schlumbergera)",
    wateringDays: 8,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.none,
    tips: ["Are nevoie de nopți mai lungi/răcoroase toamna pentru a înflori."],
  ),
  "cyclamen persicum": const CareInfo(
    commonNameRo: "Ciclamen (Cyclamen persicum)",
    wateringDays: 5,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.severe,
    tips: [
      "Udă de la bază (în farfurioară) ca să eviți putrezirea tuberculului.",
    ],
  ),
  "lavandula angustifolia": const CareInfo(
    commonNameRo: "Lavandă",
    wateringDays: 9,
    light: LightNeed.directLight,
    misting: false,
    toxicityLevel: ToxicityLevel.none,
    tips: ["Sol bine drenat, evită excesul de apă și umezeala la rădăcină."],
  ),
  "rosmarinus officinalis": const CareInfo(
    commonNameRo: "Rozmarin",
    wateringDays: 7,
    light: LightNeed.directLight,
    misting: false,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Preferă să se usuce ușor între udări, nu tolerează udarea excesivă.",
    ],
  ),
  "ocimum basilicum": const CareInfo(
    commonNameRo: "Busuioc",
    wateringDays: 3,
    light: LightNeed.directLight,
    misting: false,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Menține solul constant reavăn.",
      "Ciupește vârfurile pentru creștere stufoasă.",
    ],
  ),
  "mentha spicata": const CareInfo(
    commonNameRo: "Mentă",
    wateringDays: 4,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Îi place solul umed constant.",
      "Crește foarte invaziv, bine să fie într-un ghiveci separat.",
    ],
  ),
  "citrus limon": const CareInfo(
    commonNameRo: "Lămâi (Citrus limon)",
    wateringDays: 6,
    light: LightNeed.directLight,
    misting: false,
    toxicityLevel: ToxicityLevel.moderate,
    tips: ["Are nevoie de multă lumină directă și îngrășământ pentru citrice."],
  ),
  "solanum lycopersicum": const CareInfo(
    commonNameRo: "Roșie (Solanum lycopersicum)",
    wateringDays: 3,
    light: LightNeed.directLight,
    misting: false,
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Udare constantă și regulată, evită udarea neregulată (crapă fructele).",
    ],
  ),
  "rosa chinensis": const CareInfo(
    commonNameRo: "Trandafir",
    wateringDays: 4,
    light: LightNeed.directLight,
    misting: false,
    toxicityLevel: ToxicityLevel.none,
    tips: ["Udă la bază, evită udarea frunzelor pentru a preveni ciupercile."],
  ),
  "opuntia ficus-indica": const CareInfo(
    commonNameRo: "Cactus (Opuntia)",
    wateringDays: 20,
    light: LightNeed.directLight,
    misting: false,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Udă rar, doar când solul e complet uscat.",
      "Sol special pentru cactuși/suculente.",
    ],
  ),
  "echeveria elegans": const CareInfo(
    commonNameRo: "Echeveria",
    wateringDays: 14,
    light: LightNeed.directLight,
    misting: false,
    toxicityLevel: ToxicityLevel.none,
    tips: ["Udă de la bază, evită să uzi frunzele rozetei."],
  ),
  "calathea orbifolia": const CareInfo(
    commonNameRo: "Calathea",
    wateringDays: 5,
    light: LightNeed.weakIndirect,
    misting: true,
    toxicityLevel: ToxicityLevel.none,
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
    toxicityLevel: ToxicityLevel.moderate,
    tips: ["Evită udarea frunzelor, favorizează mucegaiul."],
  ),
  "alocasia amazonica": const CareInfo(
    commonNameRo: "Alocasia",
    wateringDays: 6,
    light: LightNeed.strongIndirect,
    misting: true,
    toxicityLevel: ToxicityLevel.moderate,
    tips: ["Preferă umiditate mare și sol constant reavăn, dar bine drenat."],
  ),
  "yucca elephantipes": const CareInfo(
    commonNameRo: "Yucca",
    wateringDays: 14,
    light: LightNeed.directLight,
    misting: false,
    toxicityLevel: ToxicityLevel.moderate,
    tips: ["Rezistentă la secetă, udă rar și abundent."],
  ),
  "ceropegia woodii": const CareInfo(
    commonNameRo: "Lanțul inimilor (Ceropegia woodii)",
    wateringDays: 12,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.none,
    tips: ["Are tuberculi care rețin apă; nu uda excesiv."],
  ),
  "dracaena marginata": const CareInfo(
    commonNameRo: "Dracaena marginata",
    wateringDays: 10,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Udă doar când primii 5 cm de sol sunt uscați.",
      "Sensibilă la excesul de clor/fluor din apa de la robinet.",
    ],
  ),
  "dieffenbachia seguine": const CareInfo(
    commonNameRo: "Dieffenbachia",
    wateringDays: 7,
    light: LightNeed.weakIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Seva este iritantă; poartă mănuși la tăiere.",
      "Tolerează lumină mai slabă, dar crește mai încet.",
    ],
  ),
  "schefflera arboricola": const CareInfo(
    commonNameRo: "Schefflera (Copacul umbrelă)",
    wateringDays: 7,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Lasă solul să se usuce la suprafață între udări.",
      "Rotește planta periodic spre lumină pentru creștere uniformă.",
    ],
  ),
  "aspidistra elatior": const CareInfo(
    commonNameRo: "Planta de fontă (Aspidistra elatior)",
    wateringDays: 10,
    light: LightNeed.shade,
    misting: false,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Extrem de tolerantă la neglijare și lumină slabă.",
      "Evită udarea excesivă; solul poate rămâne ușor uscat.",
    ],
  ),
  "monstera adansonii": const CareInfo(
    commonNameRo: "Monstera adansonii (Frunza de brânză elvețiană)",
    wateringDays: 7,
    light: LightNeed.strongIndirect,
    misting: true,
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Preferă un suport pe care să se agațe.",
      "Lasă solul să se usuce la suprafață între udări.",
    ],
  ),
  "rhaphidophora tetrasperma": const CareInfo(
    commonNameRo: "Mini Monstera (Rhaphidophora tetrasperma)",
    wateringDays: 7,
    light: LightNeed.strongIndirect,
    misting: true,
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Crește repede cu un suport tip moss pole.",
      "Udă când primii 3-4 cm de sol sunt uscați.",
    ],
  ),
  "scindapsus pictus": const CareInfo(
    commonNameRo: "Pothos satinat (Scindapsus pictus)",
    wateringDays: 8,
    light: LightNeed.weakIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Tolerează lumină mai slabă decât alte pothos.",
      "Lasă solul să se usuce bine între udări.",
    ],
  ),
  "pachira aquatica": const CareInfo(
    commonNameRo: "Copacul banilor (Pachira aquatica)",
    wateringDays: 9,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Sensibil la udarea excesivă; lasă solul să se usuce parțial.",
      "Preferă umiditate moderată și fără curenți reci.",
    ],
  ),
  "platycerium bifurcatum": const CareInfo(
    commonNameRo: "Ferigă coarne de cerb (Platycerium bifurcatum)",
    wateringDays: 7,
    light: LightNeed.strongIndirect,
    misting: true,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Preferă montare pe suport sau ghiveci suspendat.",
      "Udă prin înmuiere periodică, nu direct pe frunze.",
    ],
  ),
  "asplenium nidus": const CareInfo(
    commonNameRo: "Ferigă cuib de pasăre (Asplenium nidus)",
    wateringDays: 6,
    light: LightNeed.weakIndirect,
    misting: true,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Preferă umiditate ridicată și sol constant reavăn.",
      "Nu atinge frunza centrală nouă, e fragilă.",
    ],
  ),
  "senecio rowleyanus": const CareInfo(
    commonNameRo: "Șirag de perle (Senecio rowleyanus)",
    wateringDays: 14,
    light: LightNeed.directLight,
    misting: false,
    toxicityLevel: ToxicityLevel.mild,
    tips: [
      "Lasă solul să se usuce complet între udări.",
      "Evită udarea pe frunze (bobițe), poate duce la putrezire.",
    ],
  ),
  "kalanchoe blossfeldiana": const CareInfo(
    commonNameRo: "Kalanchoe",
    wateringDays: 9,
    light: LightNeed.directLight,
    misting: false,
    toxicityLevel: ToxicityLevel.severe,
    tips: [
      "Elimină florile ofilite pentru înflorire continuă.",
      "Udă moderat; sensibilă la exces de apă.",
    ],
  ),
  "haworthia fasciata": const CareInfo(
    commonNameRo: "Haworthia zebra (Haworthia fasciata)",
    wateringDays: 16,
    light: LightNeed.directLight,
    misting: false,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Sol special pentru cactuși/suculente, bine drenat.",
      "Udă abundent, apoi lasă solul complet uscat.",
    ],
  ),
  "euphorbia milii": const CareInfo(
    commonNameRo: "Coroana de spini (Euphorbia milii)",
    wateringDays: 10,
    light: LightNeed.directLight,
    misting: false,
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Seva este iritantă pentru piele; poartă mănuși.",
      "Lasă solul să se usuce bine între udări.",
    ],
  ),
  "ficus pumila": const CareInfo(
    commonNameRo: "Ficus pitic agățător (Ficus pumila)",
    wateringDays: 6,
    light: LightNeed.weakIndirect,
    misting: true,
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Preferă umiditate mai mare și sol constant reavăn.",
      "Poate fi tuns pentru a-și controla creșterea agățătoare.",
    ],
  ),

  // --- extindere: specii comune suplimentare, cercetate (august 2026) ---
  "dracaena reflexa": const CareInfo(
    commonNameRo: "Song of India (Dracaena reflexa)",
    wateringDays: 12,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Lasă primii 3-5 cm de sol să se usuce între udări.",
      "Frunzele galbene de la bază sunt normale, nu un semn de boală.",
    ],
  ),
  "philodendron erubescens": const CareInfo(
    commonNameRo: "Philodendron roșiatic (Philodendron erubescens)",
    wateringDays: 7,
    light: LightNeed.strongIndirect,
    misting: true,
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Are nevoie de un suport pentru cățărat pe măsură ce crește.",
      "Culoarea frunzelor noi e mai intensă la lumină bună.",
    ],
  ),
  "calathea lancifolia": const CareInfo(
    commonNameRo: "Calathea șarpe cu clopoței (Calathea lancifolia)",
    wateringDays: 5,
    light: LightNeed.weakIndirect,
    misting: true,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Preferă udare cu apă fără clor/fluor (lasă apa de la robinet o noapte).",
      "Umiditate ridicată — evită radiatoarele și curenții de aer uscat.",
    ],
  ),
  "calathea makoyana": const CareInfo(
    commonNameRo: "Calathea păun (Calathea makoyana)",
    wateringDays: 5,
    light: LightNeed.weakIndirect,
    misting: true,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Frunzele se ridică seara și coboară dimineața — comportament normal.",
      "Sensibilă la apă cu mult clor; preferă apă filtrată.",
    ],
  ),
  "ctenanthe setosa": const CareInfo(
    commonNameRo: "Ctenanthe (Ctenanthe setosa)",
    wateringDays: 5,
    light: LightNeed.weakIndirect,
    misting: true,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Ține solul constant reavăn, dar nu îmbibat.",
      "Beneficiază de umiditate ridicată, la fel ca rudele sale Calathea.",
    ],
  ),
  "begonia maculata": const CareInfo(
    commonNameRo: "Begonia cu buline (Begonia maculata)",
    wateringDays: 6,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Evită să uzi frunzele — risc de mucegai/oidiu.",
      "Lasă solul să se usuce la suprafață între udări.",
    ],
  ),
  "peperomia argyreia": const CareInfo(
    commonNameRo: "Peperomia pepene (Peperomia argyreia)",
    wateringDays: 9,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Frunzele suculente rețin apă — udare excesivă e riscul principal.",
      "Preferă un ghiveci mic, nu-i place solul prea afânat/umed.",
    ],
  ),
  "peperomia caperata": const CareInfo(
    commonNameRo: "Peperomia încrețită (Peperomia caperata)",
    wateringDays: 9,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Lasă solul să se usuce complet între udări.",
      "Compactă, potrivită pentru spații mici sau terarii.",
    ],
  ),
  "peperomia polybotrya": const CareInfo(
    commonNameRo: "Peperomia picătură de ploaie (Peperomia polybotrya)",
    wateringDays: 9,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Frunzele cărnoase indică o plantă bine udată; ridurile arată sete.",
      "Evită udarea excesivă — rădăcinile putrezesc ușor.",
    ],
  ),
  "hoya kerrii": const CareInfo(
    commonNameRo: "Hoya inimioară (Hoya kerrii)",
    wateringDays: 14,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Suculentă — udare rară, doar când solul e complet uscat.",
      "Înflorește mai greu dacă e ținută într-un ghiveci prea mare.",
    ],
  ),
  "hoya linearis": const CareInfo(
    commonNameRo: "Hoya linearis",
    wateringDays: 10,
    light: LightNeed.strongIndirect,
    misting: true,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Preferă umiditate mai mare decât alte specii de Hoya.",
      "Lăstarii lungi, subțiri beneficiază de un suport agățător.",
    ],
  ),
  "colocasia esculenta": const CareInfo(
    commonNameRo: "Urechea-elefantului (Colocasia esculenta)",
    wateringDays: 4,
    light: LightNeed.strongIndirect,
    misting: true,
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Iubește solul constant umed, spre deosebire de majoritatea plantelor de apartament.",
      "Frunzele mari beneficiază de ștergere periodică de praf.",
    ],
  ),
  "caladium bicolor": const CareInfo(
    commonNameRo: "Caladium (Caladium bicolor)",
    wateringDays: 5,
    light: LightNeed.weakIndirect,
    misting: true,
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Intră în repaus vegetativ iarna — udare mult mai rară atunci.",
      "Evită soarele direct, decolorează frunzele colorate.",
    ],
  ),
  "kalanchoe tomentosa": const CareInfo(
    commonNameRo: "Urechea-ursulețului (Kalanchoe tomentosa)",
    wateringDays: 16,
    light: LightNeed.directLight,
    misting: false,
    toxicityLevel: ToxicityLevel.severe,
    tips: [
      "Suculentă — udă doar când solul e complet uscat.",
      "Ține departe de animale: conține glicozide cardiace, ca și celelalte Kalanchoe.",
    ],
  ),
  "kalanchoe daigremontiana": const CareInfo(
    commonNameRo: "Mama miilor (Kalanchoe daigremontiana)",
    wateringDays: 16,
    light: LightNeed.directLight,
    misting: false,
    toxicityLevel: ToxicityLevel.severe,
    tips: [
      "Produce plantule pe marginea frunzelor care cad și înrădăcinează singure.",
      "Ține departe de animale de companie și copii mici — toxicitate cardiacă.",
    ],
  ),
  "portulacaria afra": const CareInfo(
    commonNameRo: "Copacul-de-jad-pitic (Portulacaria afra)",
    wateringDays: 14,
    light: LightNeed.directLight,
    misting: false,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Foarte tolerantă la neglijare, ideală pentru începători.",
      "Se înmulțește ușor din butași lăsați la uscat 1-2 zile.",
    ],
  ),
  "sedum morganianum": const CareInfo(
    commonNameRo: "Coada-măgarului (Sedum morganianum)",
    wateringDays: 14,
    light: LightNeed.directLight,
    misting: false,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Frunzele cad ușor la atingere — manevrează cu grijă.",
      "Udare doar când solul e complet uscat; nu tolerează udarea excesivă.",
    ],
  ),
  "sansevieria cylindrica": const CareInfo(
    commonNameRo: "Limba soacrei cilindrică (Sansevieria cylindrica)",
    wateringDays: 18,
    light: LightNeed.weakIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Foarte rezistentă la neglijare; udarea excesivă e principalul risc.",
      "Tolerează lumină slabă și aer uscat, ca și celelalte Sansevieria.",
    ],
  ),
  "dracaena draco": const CareInfo(
    commonNameRo: "Arborele-dragon (Dracaena draco)",
    wateringDays: 12,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Creștere foarte lentă; nu are nevoie de udări dese.",
      "Tolerează bine aerul uscat din apartamente.",
    ],
  ),
  "cycas revoluta": const CareInfo(
    commonNameRo: "Palmierul-sago (Cycas revoluta)",
    wateringDays: 10,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.severe,
    tips: [
      "Extrem de toxică pentru animale (mai ales semințele) — poate cauza insuficiență hepatică; ține strict departe de pisici/câini.",
      "Lasă solul să se usuce parțial între udări; sensibilă la udare excesivă.",
    ],
  ),
  "dypsis lutescens": const CareInfo(
    commonNameRo: "Palmierul-areca (Dypsis lutescens)",
    wateringDays: 6,
    light: LightNeed.strongIndirect,
    misting: true,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Sigur pentru animale de companie.",
      "Beneficiază de umiditate ridicată și ștergerea prafului de pe frunze.",
    ],
  ),
  "howea forsteriana": const CareInfo(
    commonNameRo: "Palmierul-kentia (Howea forsteriana)",
    wateringDays: 7,
    light: LightNeed.weakIndirect,
    misting: true,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Tolerează bine lumina slabă, ideal pentru colțuri mai întunecate.",
      "Sigur pentru animale de companie.",
    ],
  ),
  "rhapis excelsa": const CareInfo(
    commonNameRo: "Palmierul-doamnă (Rhapis excelsa)",
    wateringDays: 7,
    light: LightNeed.weakIndirect,
    misting: true,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Foarte rezistentă și cu creștere lentă.",
      "Tolerează lumină slabă mai bine decât majoritatea palmierilor.",
    ],
  ),
  "adiantum raddianum": const CareInfo(
    commonNameRo: "Feriga-de-păr-de-Venus (Adiantum raddianum)",
    wateringDays: 3,
    light: LightNeed.weakIndirect,
    misting: true,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Nu tolerează solul uscat — udare frecventă, sol constant reavăn.",
      "Are nevoie de umiditate mare; grupare cu alte plante ajută.",
    ],
  ),
  "tradescantia fluminensis": const CareInfo(
    commonNameRo: "Iarba-evreului (Tradescantia fluminensis)",
    wateringDays: 6,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.mild,
    tips: [
      "Seva poate irita ușor pielea la contact prelungit.",
      "Creștere rapidă; taie lăstarii pentru o formă stufoasă.",
    ],
  ),
  "tradescantia pallida": const CareInfo(
    commonNameRo: "Inima-purpurie (Tradescantia pallida)",
    wateringDays: 6,
    light: LightNeed.directLight,
    misting: false,
    toxicityLevel: ToxicityLevel.mild,
    tips: [
      "Culoarea violet e mai intensă la lumină puternică.",
      "Seva poate irita ușor pielea sensibilă.",
    ],
  ),
  "oxalis triangularis": const CareInfo(
    commonNameRo: "Trifoiul-purpuriu (Oxalis triangularis)",
    wateringDays: 6,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Frunzele se închid noaptea și se redeschid dimineața — normal.",
      "Conține acid oxalic; ține departe de animale care mestecă frunze.",
    ],
  ),
  "saintpaulia ionantha": const CareInfo(
    commonNameRo: "Violeta-africană (Saintpaulia ionantha)",
    wateringDays: 6,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Udă direct în sol, evită udarea pe frunze — pot apărea pete.",
      "Preferă lumină indirectă constantă, fără soare direct puternic.",
    ],
  ),
  "euphorbia tirucalli": const CareInfo(
    commonNameRo: "Copacul-de-creioane (Euphorbia tirucalli)",
    wateringDays: 14,
    light: LightNeed.directLight,
    misting: false,
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Seva albă e iritantă pentru piele și ochi — poartă mănuși la manevrare.",
      "Foarte tolerantă la secetă; udare rară, doar când solul e uscat.",
    ],
  ),
  "rhipsalis baccifera": const CareInfo(
    commonNameRo: "Cactusul-vâsc (Rhipsalis baccifera)",
    wateringDays: 9,
    light: LightNeed.weakIndirect,
    misting: true,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Spre deosebire de cactușii de deșert, preferă umiditate și lumină mai slabă.",
      "Lăstarii agățători arată bine în ghivece suspendate.",
    ],
  ),
  "epiphyllum oxypetalum": const CareInfo(
    commonNameRo: "Regina-nopții (Epiphyllum oxypetalum)",
    wateringDays: 9,
    light: LightNeed.strongIndirect,
    misting: true,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Înflorește noaptea, rar, cu flori spectaculoase de scurtă durată.",
      "Preferă un amestec de sol afânat, ca pentru epifite.",
    ],
  ),
  "mammillaria elongata": const CareInfo(
    commonNameRo: "Cactusul-deget (Mammillaria elongata)",
    wateringDays: 16,
    light: LightNeed.directLight,
    misting: false,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Udare rară, doar când solul e complet uscat.",
      "Are nevoie de câteva ore de soare direct pe zi pentru o creștere sănătoasă.",
    ],
  ),
  "gynura aurantiaca": const CareInfo(
    commonNameRo: "Catifeaua-purpurie (Gynura aurantiaca)",
    wateringDays: 6,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Perii violeți de pe frunze sunt mai intenși la lumină bună.",
      "Evită soarele direct la prânz — poate arde frunzele fine.",
    ],
  ),
  "cissus rhombifolia": const CareInfo(
    commonNameRo: "Vița-de-vie-de-interior (Cissus rhombifolia)",
    wateringDays: 7,
    light: LightNeed.weakIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Cățărătoare rapidă; beneficiază de un suport.",
      "Tolerantă la condiții variate de lumină și udare neregulată.",
    ],
  ),
  "mesembryanthemum cordifolium": const CareInfo(
    commonNameRo: "Iarbă-de-gheață (Mesembryanthemum cordifolium)",
    wateringDays: 12,
    light: LightNeed.directLight,
    misting: false,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Suculentă acoperitoare de sol — lasă solul să se usuce complet între udări.",
      "Are nevoie de câteva ore de soare direct pe zi ca să înflorească.",
    ],
  ),
  "aptenia cordifolia": const CareInfo(
    commonNameRo: "Iarbă-de-gheață (Aptenia cordifolia)",
    wateringDays: 12,
    light: LightNeed.directLight,
    misting: false,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Suculentă acoperitoare de sol — lasă solul să se usuce complet între udări.",
      "Are nevoie de câteva ore de soare direct pe zi ca să înflorească.",
    ],
  ),
  "delosperma cooperi": const CareInfo(
    commonNameRo: "Iarbă-de-gheață violet (Delosperma cooperi)",
    wateringDays: 14,
    light: LightNeed.directLight,
    misting: false,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Foarte rezistentă la secetă; udarea excesivă îi putrezește rădăcinile.",
      "Preferă un loc cu soare direct, cald.",
    ],
  ),
};

const CareInfo kGenericFallbackCare = CareInfo(
  commonNameRo: "Plantă neidentificată exact în baza de îngrijire",
  wateringDays: 7,
  light: LightNeed.strongIndirect,
  misting: false,
  toxicityLevel: ToxicityLevel.none,
  tips: [
    "Verifică solul cu degetul: udă când primii 2-3 cm sunt uscați.",
    "Evită apa stătută în farfurioară.",
    "Așază planta într-o zonă cu lumină indirectă, ferită de soare direct puternic la prânz.",
    "Aceste informații sunt generale — ajustează în funcție de cum reacționează planta ta.",
  ],
);

// Profiluri orientative pe familie botanică — folosite doar când o specie nu
// are intrare exactă/înrudită după gen în `kCareDb`. Nu sunt date exacte per
// specie, ci o aproximare rezonabilă a nevoilor tipice ale familiei (ex.
// orice Araceae tinde spre udare săptămânală + toxicitate moderată din
// oxalat de calciu). Unde familia conține atât specii toxice cât și
// netoxice, am ales varianta prudentă (nivelul mai ridicat), ca să nu
// subestimăm riscul.
final Map<String, CareInfo> kFamilyCareDefaults = {
  "araceae": const CareInfo(
    commonNameRo: "Plantă din familia Araceae",
    wateringDays: 7,
    light: LightNeed.strongIndirect,
    misting: true,
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Majoritatea plantelor din această familie (Monstera, Philodendron, Pothos, Anthurium) preferă solul reavăn, nu ud.",
      "Conțin oxalat de calciu — ține departe de animale care mestecă frunze.",
    ],
  ),
  "asparagaceae": const CareInfo(
    commonNameRo: "Plantă din familia Asparagaceae",
    wateringDays: 16,
    light: LightNeed.weakIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Familia Sansevieria/Dracaena — foarte tolerantă la neglijare, udarea excesivă e principalul risc.",
      "Lasă solul complet uscat între udări.",
    ],
  ),
  "cactaceae": const CareInfo(
    commonNameRo: "Cactus (familia Cactaceae)",
    wateringDays: 16,
    light: LightNeed.directLight,
    misting: false,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Udă doar când solul e complet uscat.",
      "Are nevoie de câteva ore de soare direct pe zi pentru o creștere sănătoasă.",
    ],
  ),
  "crassulaceae": const CareInfo(
    commonNameRo: "Suculentă din familia Crassulaceae",
    wateringDays: 14,
    light: LightNeed.directLight,
    misting: false,
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Familia Echeveria/Sedum/Kalanchoe/Crassula — udare rară, doar când solul e uscat.",
      "Unele specii din familie (Kalanchoe) sunt toxice pentru animale — verifică specia exactă dacă ai animale.",
    ],
  ),
  "moraceae": const CareInfo(
    commonNameRo: "Plantă din familia Moraceae (Ficus)",
    wateringDays: 9,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Nu-i place să fie mutată des; poate pierde frunze dacă e stresată.",
      "Seva poate irita pielea sensibilă la contact.",
    ],
  ),
  "marantaceae": const CareInfo(
    commonNameRo: "Plantă din familia Marantaceae",
    wateringDays: 5,
    light: LightNeed.weakIndirect,
    misting: true,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Familia Calathea/Maranta/Ctenanthe — preferă umiditate ridicată și apă fără mult clor.",
      "Frunzele se mișcă în funcție de lumină — comportament normal.",
    ],
  ),
  "piperaceae": const CareInfo(
    commonNameRo: "Plantă din familia Piperaceae (Peperomia)",
    wateringDays: 9,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Frunzele suculente rețin apă — udarea excesivă e riscul principal.",
      "Preferă un ghiveci mic, cu sol care se usucă rapid.",
    ],
  ),
  "apocynaceae": const CareInfo(
    commonNameRo: "Plantă din familia Apocynaceae",
    wateringDays: 12,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.mild,
    tips: [
      "Familia include Hoya, dar și specii ornamentale mai toxice — ai grijă dacă ai animale.",
      "Lasă solul să se usuce parțial între udări.",
    ],
  ),
  "asphodelaceae": const CareInfo(
    commonNameRo: "Plantă din familia Asphodelaceae (Aloe)",
    wateringDays: 14,
    light: LightNeed.directLight,
    misting: false,
    toxicityLevel: ToxicityLevel.mild,
    tips: [
      "Familia Aloe/Haworthia/Gasteria — udare rară, sol bine drenat.",
      "Tolerează lumină puternică și aer uscat.",
    ],
  ),
  "arecaceae": const CareInfo(
    commonNameRo: "Palmier (familia Arecaceae)",
    wateringDays: 7,
    light: LightNeed.weakIndirect,
    misting: true,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Majoritatea palmierilor de interior sunt sigure pentru animale.",
      "Beneficiază de umiditate ridicată și ștergerea prafului de pe frunze.",
    ],
  ),
  "polypodiaceae": const CareInfo(
    commonNameRo: "Ferigă (familia Polypodiaceae)",
    wateringDays: 4,
    light: LightNeed.weakIndirect,
    misting: true,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Feriga nu tolerează solul uscat — udare frecventă, umiditate ridicată.",
      "Evită lumina directă puternică, arde frunzele fine.",
    ],
  ),
  "nephrolepidaceae": const CareInfo(
    commonNameRo: "Ferigă (familia Nephrolepidaceae)",
    wateringDays: 4,
    light: LightNeed.weakIndirect,
    misting: true,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Feriga nu tolerează solul uscat — udare frecventă, umiditate ridicată.",
      "Evită lumina directă puternică, arde frunzele fine.",
    ],
  ),
  "aspleniaceae": const CareInfo(
    commonNameRo: "Ferigă (familia Aspleniaceae)",
    wateringDays: 4,
    light: LightNeed.weakIndirect,
    misting: true,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Feriga nu tolerează solul uscat — udare frecventă, umiditate ridicată.",
      "Evită lumina directă puternică, arde frunzele fine.",
    ],
  ),
  "pteridaceae": const CareInfo(
    commonNameRo: "Ferigă (familia Pteridaceae)",
    wateringDays: 3,
    light: LightNeed.weakIndirect,
    misting: true,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Feriga nu tolerează solul uscat — udare frecventă, umiditate ridicată.",
      "Sensibilă la aer uscat; grupare cu alte plante ajută.",
    ],
  ),
  "begoniaceae": const CareInfo(
    commonNameRo: "Plantă din familia Begoniaceae",
    wateringDays: 6,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Evită să uzi frunzele — risc de mucegai/oidiu.",
      "Lasă solul să se usuce la suprafață între udări.",
    ],
  ),
  "gesneriaceae": const CareInfo(
    commonNameRo: "Plantă din familia Gesneriaceae",
    wateringDays: 6,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Familia African violet/Streptocarpus — udă direct în sol, evită frunzele.",
      "Preferă lumină indirectă constantă, fără soare direct puternic.",
    ],
  ),
  "commelinaceae": const CareInfo(
    commonNameRo: "Plantă din familia Commelinaceae",
    wateringDays: 6,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.mild,
    tips: [
      "Familia Tradescantia — creștere rapidă, taie lăstarii pentru formă stufoasă.",
      "Seva poate irita ușor pielea sensibilă.",
    ],
  ),
  "euphorbiaceae": const CareInfo(
    commonNameRo: "Plantă din familia Euphorbiaceae",
    wateringDays: 12,
    light: LightNeed.directLight,
    misting: false,
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Seva albă (latex) e iritantă pentru piele și ochi — poartă mănuși.",
      "Majoritatea speciilor din familie tolerează bine seceta.",
    ],
  ),
  "oxalidaceae": const CareInfo(
    commonNameRo: "Plantă din familia Oxalidaceae",
    wateringDays: 6,
    light: LightNeed.strongIndirect,
    misting: false,
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Conține acid oxalic; ține departe de animale care mestecă frunze.",
      "Frunzele se pot închide noaptea — comportament normal.",
    ],
  ),
  "lamiaceae": const CareInfo(
    commonNameRo: "Plantă aromatică din familia Lamiaceae",
    wateringDays: 5,
    light: LightNeed.directLight,
    misting: false,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Familia mentei/busuiocului/rozmarinului — preferă soare bun și udare moderată.",
      "Ciupește vârfurile des pentru o creștere stufoasă.",
    ],
  ),
  "solanaceae": const CareInfo(
    commonNameRo: "Plantă din familia Solanaceae",
    wateringDays: 5,
    light: LightNeed.directLight,
    misting: false,
    toxicityLevel: ToxicityLevel.moderate,
    tips: [
      "Familia include tomate și rude ornamentale — frunzele/tulpina pot fi toxice chiar dacă fructul se mănâncă.",
      "Preferă lumină puternică și udare constantă.",
    ],
  ),
  "rosaceae": const CareInfo(
    commonNameRo: "Plantă din familia Rosaceae",
    wateringDays: 5,
    light: LightNeed.directLight,
    misting: false,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Preferă lumină puternică, ideal câteva ore de soare direct.",
      "Udă când solul e ușor uscat la suprafață.",
    ],
  ),
  "aizoaceae": const CareInfo(
    commonNameRo: "Suculentă din familia Aizoaceae (iarbă-de-gheață)",
    wateringDays: 12,
    light: LightNeed.directLight,
    misting: false,
    toxicityLevel: ToxicityLevel.none,
    tips: [
      "Familia iarbă-de-gheață/Lithops — udare rară, sol bine drenat.",
      "Are nevoie de soare direct din belșug pentru a înflori.",
    ],
  ),
};

/// Caută date de îngrijire pentru o specie: (1) intrare exactă în
/// `kCareDb`, (2) o specie înrudită din același gen, (3) — dacă avem
/// familia botanică (de la Pl@ntNet) — un profil orientativ pe familie,
/// (4) fallback generic complet. Pasul (3) e ce face aplicația să acopere
/// practic orice specie identificabilă, nu doar cele curatoriate exact.
CareInfo getCareInfo(String scientificName, {String? family}) {
  final key = scientificName.trim().toLowerCase();
  final exact = kCareDb[key];
  if (exact != null) return exact;

  final genus = key.split(" ").first;
  for (final entry in kCareDb.entries) {
    if (entry.key.startsWith("$genus ")) {
      return entry.value.copyWith(
        commonNameRo: "${entry.value.commonNameRo} (specie înrudită)",
      );
    }
  }

  final familyKey = family?.trim().toLowerCase();
  if (familyKey != null) {
    final familyDefault = kFamilyCareDefaults[familyKey];
    if (familyDefault != null) {
      return familyDefault.copyWith(
        commonNameRo:
            "$scientificName (${familyDefault.commonNameRo.toLowerCase()})",
      );
    }
  }

  return kGenericFallbackCare;
}
