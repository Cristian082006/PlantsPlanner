/// Curated representative photos for the species in the local care database
/// (see `care_info.dart`). Hand-picked from Wikimedia Commons because
/// Wikipedia's own article thumbnail is sometimes a flower/fruit closeup, a
/// synonym-redirect photo of a different-looking form, or otherwise not
/// representative of the plant as commonly recognized (e.g. "Dracaena
/// marginata" redirects to a plain-green "Dracaena reflexa" photo instead of
/// the red-edged dragon tree cultivar most people mean).
const Map<String, String> kSpeciesThumbnails = {
  'epipremnum aureum':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1c/Epipremnum-aureum-poznan-palmiarnia-abrimaal.jpg/500px-Epipremnum-aureum-poznan-palmiarnia-abrimaal.jpg',
  'monstera deliciosa':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2e/Monstera_deliciosa2.jpg/500px-Monstera_deliciosa2.jpg',
  'sansevieria trifasciata':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/e/eb/20210623_Hortus_botanicus_Leiden_-_Sansevieria_trifasciata_v2.jpg/500px-20210623_Hortus_botanicus_Leiden_-_Sansevieria_trifasciata_v2.jpg',
  'dracaena trifasciata':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3d/Dracaena_Trifasciata_Plant.jpg/500px-Dracaena_Trifasciata_Plant.jpg',
  'ficus elastica':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4f/Ficus_elastica_2.jpg/500px-Ficus_elastica_2.jpg',
  'ficus lyrata':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2d/Ficus_lyrata_153481648.jpg/500px-Ficus_lyrata_153481648.jpg',
  'ficus benjamina':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a0/BBG_-_Ficus_benjamina_-_Forrest.jpg/500px-BBG_-_Ficus_benjamina_-_Forrest.jpg',
  'chlorophytum comosum':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c4/Chlorophytum_comosum_in_China.jpg/500px-Chlorophytum_comosum_in_China.jpg',
  'spathiphyllum wallisii':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/5/54/SpathiphyllumWallisii.jpg/500px-SpathiphyllumWallisii.jpg',
  'zamioculcas zamiifolia':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7f/%22Zamio_Mater%22_Zamioculcas_zamiifolia_communis_plant.jpg/500px-%22Zamio_Mater%22_Zamioculcas_zamiifolia_communis_plant.jpg',
  'aloe vera':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/8/80/Aloe-Vera-Sitia-Crete-Greece.jpg/500px-Aloe-Vera-Sitia-Crete-Greece.jpg',
  'crassula ovata':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/%28MHNT%29_Crassula_ovata_-_Serres_du_Museum_de_Toulouse.jpg/500px-%28MHNT%29_Crassula_ovata_-_Serres_du_Museum_de_Toulouse.jpg',
  'philodendron hederaceum':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7f/Philodendron_hederaceum%2C_Singapore_Botanic_Gardens_%28141542%29.jpg/500px-Philodendron_hederaceum%2C_Singapore_Botanic_Gardens_%28141542%29.jpg',
  'dracaena fragrans':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f0/2013-Dracaena_fragrans_fleur.jpg/500px-2013-Dracaena_fragrans_fleur.jpg',
  'peperomia obtusifolia':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c4/Peperomia_Obtusifolia.jpg/500px-Peperomia_Obtusifolia.jpg',
  'hedera helix':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c8/Ivy_Hedera_Red_Brick_Wall_2892px.jpg/500px-Ivy_Hedera_Red_Brick_Wall_2892px.jpg',
  'aglaonema commutatum':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6d/20260317_Aglaonema_commutatum.jpg/500px-20260317_Aglaonema_commutatum.jpg',
  'anthurium andraeanum':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Anthurium_andraeanum%2C_jard%C3%ADn_bot%C3%A1nico_de_Tallinn%2C_Estonia%2C_2012-08-13%2C_DD_01.JPG/500px-Anthurium_andraeanum%2C_jard%C3%ADn_bot%C3%A1nico_de_Tallinn%2C_Estonia%2C_2012-08-13%2C_DD_01.JPG',
  'tradescantia zebrina':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2e/20260317_Tradescantia_zebrina_01.jpg/500px-20260317_Tradescantia_zebrina_01.jpg',
  'nephrolepis exaltata':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c2/Helecho_de_Boston_%28Nephrolepis_exaltata%29.jpg/500px-Helecho_de_Boston_%28Nephrolepis_exaltata%29.jpg',
  'chamaedorea elegans':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f5/Chamaedorea_elegans.jpg/500px-Chamaedorea_elegans.jpg',
  'beaucarnea recurvata':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/9/95/Beaucarnea_recurvata%2C_Llera%2C_Tamaulipas%2C_Mexico_1.jpg/500px-Beaucarnea_recurvata%2C_Llera%2C_Tamaulipas%2C_Mexico_1.jpg',
  'pilea peperomioides':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f6/%28MHNT%29_Pilea_peperomioides_Foliage.jpg/500px-%28MHNT%29_Pilea_peperomioides_Foliage.jpg',
  'maranta leuconeura':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4a/Maranta_leuconeura3.jpg/500px-Maranta_leuconeura3.jpg',
  'syngonium podophyllum':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ec/Syngonium-podophyllum-SF23278-01.jpg/500px-Syngonium-podophyllum-SF23278-01.jpg',
  'strelitzia reginae':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c8/20260411_Strelitzia_reginae.jpg/500px-20260411_Strelitzia_reginae.jpg',
  'codiaeum variegatum':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6a/Codiaeum-variegatum-SF25288-02.jpg/500px-Codiaeum-variegatum-SF25288-02.jpg',
  'fittonia albivenis':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/46/Fittonia_albivenis_61868979.jpg/500px-Fittonia_albivenis_61868979.jpg',
  'hoya carnosa':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9d/Hoya_carnosa.jpeg/500px-Hoya_carnosa.jpeg',
  'euphorbia trigona':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3f/African_milk_tree_%28Euphorbia_trigona%29.jpg/500px-African_milk_tree_%28Euphorbia_trigona%29.jpg',
  'schlumbergera truncata':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fd/Schlumbergera_Truncata.jpg/500px-Schlumbergera_Truncata.jpg',
  'cyclamen persicum':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0d/CyclamenPersicumMill20.jpg/500px-CyclamenPersicumMill20.jpg',
  'lavandula angustifolia':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/b/be/%28MHNT%29_Bombus_pascuorum_on_Lavandula_angustifolia.jpg/500px-%28MHNT%29_Bombus_pascuorum_on_Lavandula_angustifolia.jpg',
  'rosmarinus officinalis':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5f/Rosmarinus_officinalis133095382.jpg/500px-Rosmarinus_officinalis133095382.jpg',
  'ocimum basilicum':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Basil-Basilico-Ocimum_basilicum-albahaca.jpg/500px-Basil-Basilico-Ocimum_basilicum-albahaca.jpg',
  'mentha spicata':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ac/00_1984_Gr%C3%BCne_Minze_%28Mentha_Spicata%29_-_Schmetterling_%28Weissling%29.jpg/500px-00_1984_Gr%C3%BCne_Minze_%28Mentha_Spicata%29_-_Schmetterling_%28Weissling%29.jpg',
  'citrus limon':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/0/08/Citrus_x_limon_%28Outjo%29.jpg/500px-Citrus_x_limon_%28Outjo%29.jpg',
  'solanum lycopersicum':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/8/83/Maduraci%C3%B3n_del_tomate_%28Solanum_lycopersicum%29.jpg/500px-Maduraci%C3%B3n_del_tomate_%28Solanum_lycopersicum%29.jpg',
  'rosa chinensis':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e2/%28MHNT%29_Tropinota_squalida_on_Rosa_chinensis.jpg/500px-%28MHNT%29_Tropinota_squalida_on_Rosa_chinensis.jpg',
  'opuntia ficus-indica':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/Hint_inciri_-_Indian_fig_-_Opuntia_ficus-indica_01.JPG/500px-Hint_inciri_-_Indian_fig_-_Opuntia_ficus-indica_01.JPG',
  'echeveria elegans':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/9/96/Echeveria-elegans-rose.jpg/500px-Echeveria-elegans-rose.jpg',
  'calathea orbifolia':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/d/dc/Calathea_orbifolia-1-my_chedi-foot_hill-yercaud-salem-India.jpg/500px-Calathea_orbifolia-1-my_chedi-foot_hill-yercaud-salem-India.jpg',
  'begonia rex':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/0/06/Begonia_rex.jpg/500px-Begonia_rex.jpg',
  'alocasia amazonica':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1c/Alocasia_amazonica_var.jpg/500px-Alocasia_amazonica_var.jpg',
  'yucca elephantipes':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d1/Yucca_elephantipes_HRM2.JPG/500px-Yucca_elephantipes_HRM2.JPG',
  'ceropegia woodii':
      'https://upload.wikimedia.org/wikipedia/commons/5/55/Ceropegia_linearis_subsp_woodii.jpg',
  'dracaena marginata':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f9/Dracaena_marginata_IndoorPlant_0605k.jpg/330px-Dracaena_marginata_IndoorPlant_0605k.jpg',
  'dieffenbachia seguine':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3e/Dieffenbachia_seguine_kz05.jpg/500px-Dieffenbachia_seguine_kz05.jpg',
  'schefflera arboricola':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/8/85/Dwarf_Umbrella_Tree_%28Schefflera_arboricola%29.jpg/500px-Dwarf_Umbrella_Tree_%28Schefflera_arboricola%29.jpg',
  'aspidistra elatior':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/8/83/Aspidistra-elatior-variegata.jpg/500px-Aspidistra-elatior-variegata.jpg',
  'monstera adansonii':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/24/Monstera_adansonii_112059105.jpg/500px-Monstera_adansonii_112059105.jpg',
  'rhaphidophora tetrasperma':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/d/db/Rhaphidophora_tetrasperma.jpg/500px-Rhaphidophora_tetrasperma.jpg',
  'scindapsus pictus':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/ca/Scindapsus_pictus_01.jpg/500px-Scindapsus_pictus_01.jpg',
  'pachira aquatica':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1b/Pachira_aquatica_at_Olbrich.jpg/500px-Pachira_aquatica_at_Olbrich.jpg',
  'platycerium bifurcatum':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9c/Platycerium-bifurcatum-SF24298-01.jpg/500px-Platycerium-bifurcatum-SF24298-01.jpg',
  'asplenium nidus':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/3/37/Asplenium-nidus-SF24082-02.jpg/500px-Asplenium-nidus-SF24082-02.jpg',
  'senecio rowleyanus':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4a/Curio_rowleyanus_syn._Senecio_rowleyanus_2019-04-14_01.jpg/500px-Curio_rowleyanus_syn._Senecio_rowleyanus_2019-04-14_01.jpg',
  'kalanchoe blossfeldiana':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/0/03/2025_Kalanchoe_blossfeldiana_Poelin._Santiago_de_Compostela._Galiza-2.jpg/500px-2025_Kalanchoe_blossfeldiana_Poelin._Santiago_de_Compostela._Galiza-2.jpg',
  'haworthia fasciata':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5c/1_Haworthia_fasciata_-MBB_Kabeljouws_River.jpg/500px-1_Haworthia_fasciata_-MBB_Kabeljouws_River.jpg',
  'euphorbia milii':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e6/Euphorbia_Milii-crown_of_Thorns.jpg/500px-Euphorbia_Milii-crown_of_Thorns.jpg',
  'ficus pumila':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fd/%28Arya%29_Ficus_pumila_in_front_of_hotel_citradream_Cirebon_2019_0.jpg/500px-%28Arya%29_Ficus_pumila_in_front_of_hotel_citradream_Cirebon_2019_0.jpg',
};
