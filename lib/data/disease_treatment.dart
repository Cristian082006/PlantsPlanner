/// Pl@ntNet's diseases endpoint only returns a name/description from the
/// EPPO database, no treatment guidance — so this maps common keywords in
/// that (English) description to general Romanian care advice. It's
/// deliberately generic (matched by problem *category*, not exact EPPO
/// code) since curating per-code treatment for thousands of EPPO entries
/// isn't feasible; always framed as a starting point, not a diagnosis.
String treatmentAdviceRo(String description) {
  final d = description.toLowerCase();

  if (d.contains('virus') || d.contains('mosaic')) {
    return 'Bolile virale nu au tratament direct: izolează planta de celelalte, elimină frunzele afectate și dezinfectează foarfeca/uneltele între tăieri, ca să nu răspândești virusul.';
  }
  if (d.contains('mite')) {
    return 'Tratează cu ulei de neem sau săpun insecticid, pulverizează și pe partea de jos a frunzelor, și crește umiditatea din jur — acarienii preferă aerul uscat.';
  }
  if (d.contains('aphid')) {
    return 'Șterge frunzele cu un burete înmuiat în apă cu săpun sau pulverizează ulei de neem; repetă la 5-7 zile până dispar dăunătorii.';
  }
  if (d.contains('scale')) {
    return 'Îndepărtează manual insectele cu un tampon cu alcool, apoi tratează cu ulei horticol sau neem.';
  }
  if (d.contains('miner')) {
    return 'Taie și elimină frunzele cu galerii vizibile (dâre albicioase), apoi tratează cu insecticid sistemic dacă infestarea persistă.';
  }
  if (d.contains('rot')) {
    return 'Oprește udarea excesivă, scoate planta din ghiveci, taie rădăcinile/țesutul afectat și replantează în sol proaspăt, bine drenat.';
  }
  if (d.contains('mildew') || d.contains('mold') || d.contains('mould')) {
    return 'Îmbunătățește circulația aerului, evită udarea pe frunze și tratează cu un fungicid pe bază de cupru sau bicarbonat de sodiu diluat.';
  }
  if (d.contains('blight') || d.contains('rust') || d.contains('spot')) {
    return 'Elimină imediat țesutul afectat, evită udarea de sus (pe frunze) și tratează cu un fungicid potrivit pentru boli foliare.';
  }
  if (d.contains('bacteri')) {
    return 'Bolile bacteriene se răspândesc prin apă și unelte: izolează planta, evită stropirea frunzelor și dezinfectează foarfeca după fiecare tăiere.';
  }
  if (d.contains('unknown') || d.contains('non-parasitic') || d.contains('nutrition') || d.contains('deficiency')) {
    return 'Poate fi o problemă de îngrijire, nu o boală: verifică udarea, lumina și fertilizarea — simptomele non-parazitare dispar de obicei odată corectate condițiile.';
  }

  return 'Izolează planta de celelalte până lămurești problema, îndepărtează părțile clar afectate și monitorizeaz-o în zilele următoare pentru evoluție.';
}
