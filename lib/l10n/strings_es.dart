// lib/l10n/strings_es.dart
// Spanish implementation of AppStrings.
import 'strings_en.dart';

class AppStringsEs implements AppStrings {
  const AppStringsEs();

  // ── App ──────────────────────────────────────────────────────────────────────
  @override String get appTitle => 'Comparar Ofertas';

  // ── Home ─────────────────────────────────────────────────────────────────────
  @override String get compareOffers => 'Comparar ofertas';
  @override String get compare => 'Comparar';
  @override String get history => 'Historial';
  @override String get pleaseFixErrors => 'Por favor corrige los errores';

  // ── Hero ──────────────────────────────────────────────────────────────────────
  @override String get heroTitle => 'Compara tu compensación real';
  @override String get heroSubtitle => 'Salario neto, impuestos, beneficios y más';
  @override String get heroChip51States => '51 estados';
  @override String get heroChip3Offers => '3 Ofertas';

  // ── Add / Remove offer C ──────────────────────────────────────────────────────
  @override String get add3rdOffer => 'Agregar 3ª oferta';
  @override String get remove3rdOffer => 'Quitar 3ª oferta';

  // ── Offer form card ───────────────────────────────────────────────────────────
  @override String get offerA => 'Oferta A';
  @override String get offerB => 'Oferta B';
  @override String get offerC => 'Oferta C';
  @override String get offerName => 'Nombre';
  @override String get company => 'Empresa';
  @override String get pasteOfferLetter => 'Pegar carta de oferta';
  @override String get newBadge => 'NUEVO';
  @override String get annual => 'Por año';
  @override String get hourly => 'Por hora';
  @override String get hourlySalaryLabel => 'Salario por hora (\$)';
  @override String get annualSalaryLabel => 'Salario anual (\$)';
  @override String get hrsWeek => 'hrs/sem';
  @override String get bonusPct => 'Bono (%)';
  @override String get ptoDays => 'Días PTO';
  @override String get signingBonus => 'Bono de contratación (\$)';
  @override String get upTo => 'Hasta (%)';
  @override String get healthPerYr => 'Salud (\$/año)';
  @override String get dentalPerYr => 'Dental (\$/año)';
  @override String get annualRsuStock => 'RSU/Stock anual (\$)';
  @override String get milesOneWayCommute => 'Millas ida al trabajo';
  @override String get annualRaisePct => 'Aumento anual (%)';
  @override String get remoteWork => 'Trabajo remoto';
  @override String get cityColLabel => 'Ciudad (costo de vida)';
  @override String get state => 'Estado';
  @override String get noDeadline => 'Sin fecha límite';
  @override String get offerDeadline => 'Fecha límite:';
  @override String get daysLeft => 'días restantes';
  @override String get deadlineExpired => 'Vencida';
  @override String get hidebenefits => 'Ocultar beneficios';
  @override String get benefitsAndCommute => '+ Beneficios y transporte';
  @override String get benefits401kRsuHealth => '401k · RSU · Salud';
  @override String get median => 'mediana';
  @override String get aboveMarket => 'sobre el mercado';
  @override String get belowMarket => 'bajo el mercado';
  @override String get atMarket => 'en el mercado';
  @override String get required => 'Requerido';
  @override String get invalidNumber => 'Número inválido';
  @override String get mustBeGte0 => 'Debe ser ≥ 0';
  @override String get perYear => '/año';

  // ── Comparison screen ─────────────────────────────────────────────────────────
  @override String get export => 'Exportar';
  @override String get exportCsv => 'Exportar CSV';
  @override String get exportCsvSubtitle => 'Compatible con Excel y Sheets';
  @override String get exportPdf => 'Exportar PDF';
  @override String get exportPdfSubtitlePremium => 'Reporte completo';
  @override String get exportPdfSubtitleLocked => 'Premium — desbloquear';
  @override String get cancel => 'Cancelar';
  @override String get pdfGenerated => 'PDF generado ✓';
  @override String get failedExportPdf => 'Error al generar PDF';
  @override String get failedExportCsv => 'Error al exportar CSV';
  @override String get scenarioSaved => 'Escenario guardado';
  @override String get failedSave => 'Error al guardar';
  @override String get exportPdfReport => 'Exportar reporte PDF';
  @override String get unlimitedSavedScenarios => 'Escenarios guardados ilimitados';
  @override String get unlimitedSavedScenariosSubtitle =>
      'Guarda y nombra todas tus comparaciones sin límite';
  @override String get realPurchasingPower => 'Poder Adquisitivo Real';
  @override String get realPurchasingPowerByCity => 'Poder adquisitivo real por ciudad';
  @override String get colAdjustedTakeHome => 'Salario ajustado por costo de vida';
  @override String get nyc100kNeqDallas => '\$100k en NYC ≠ \$100k en Dallas';
  @override String get longTermWealthAnalysis => 'Análisis de riqueza a largo plazo';
  @override String get longTermWealthSubtitle =>
      'Proyección 5 años · 401k a jubilación · Riqueza neta · Punto de equilibrio';
  @override String get scenarioSavedLabel => 'Escenario guardado';

  // ── CSV headers ───────────────────────────────────────────────────────────────
  @override String get field => 'Campo';
  @override String get grossSalary => 'Salario bruto';
  @override String get city => 'Ciudad';
  @override String get stateLabel => 'Estado';
  @override String get netAnnualTakeHome => 'Ingreso neto anual';
  @override String get netMonthly => 'Ingreso neto mensual';
  @override String get effectiveTaxRate => 'Tasa efectiva';
  @override String get federalTax => 'Impuesto federal';
  @override String get stateTax => 'Impuesto estatal';
  @override String get annualBonusAfterTax => 'Bono anual (neto)';
  @override String get signingBonusAfterTax => 'Bono contratación (neto)';
  @override String get match401k => 'Match 401k';
  @override String get healthBenefits => 'Beneficios salud';
  @override String get ptoValue => 'Valor PTO';
  @override String get annualRsu => 'RSU anual';
  @override String get commuteCost => 'Costo traslado';
  @override String get totalNetCompensation => 'Compensación total neta';

  // ── PDF ───────────────────────────────────────────────────────────────────────
  @override String get pdfTitle => 'Comparación de Ofertas de Trabajo';
  @override String get generated => 'Generado';
  @override String get pdfDisclaimer =>
      'Nota: Este reporte es solo informativo. Consulte a un asesor fiscal.';
  @override String get metric => 'Métrica';
  @override String get offerALabel => 'Oferta A';
  @override String get offerBLabel => 'Oferta B';
  @override String get offerCLabel => 'Oferta C';
  @override String get advantage => 'ventaja';
  @override String get offerAWins => 'Oferta A gana';
  @override String get offerBWins => 'Oferta B gana';
  @override String get offerCWins => 'Oferta C gana';
  @override String get tie => 'Empate';

  // ── Comparison sections ────────────────────────────────────────────────────────
  @override String get afterTaxIncome => 'Salario Neto';
  @override String get annualTakeHome => 'Salario neto anual';
  @override String get monthly => 'Mensual';
  @override String get effectiveTaxRateLabel => 'Tasa impositiva efectiva';
  @override String get taxBreakdown => 'Desglose de Impuestos';
  @override String get federalTaxLabel => 'Impuesto federal';
  @override String get stateTaxLabel => 'Impuesto estatal';
  @override String get cityLocalTax => 'Impuesto ciudad';
  @override String get benefitsAndExtras => 'Beneficios y Extras';
  @override String get annualBonusAfterTaxLabel => 'Bono neto anual';
  @override String get signingBonusAfterTaxLabel => 'Bono de contratación (neto)';
  @override String get k401kEmployerMatch => '401k (aporte empleador)';
  @override String get healthPlusDental => 'Salud + dental';
  @override String get ptoValueLabel => 'Valor vacaciones (PTO)';
  @override String get annualRsuStock2 => 'RSU / Stock anual';
  @override String get commuteCosMinus => 'Costo transporte (−)';
  @override String get rsuVestingSchedule => 'Calendario de Adquisición RSU';
  @override String get netTotalCompensation => 'Compensación Total Neta';
  @override String get totalAnnualNet => 'Total anual neto';
  @override String get totalMonthlyNet => 'Total mensual neto';

  // ── Hero KPI ──────────────────────────────────────────────────────────────────
  @override String get totalCompensation => 'Compensación total';
  @override String get bothOffersEquivalent => 'Las dos ofertas son equivalentes';
  @override String get annualNetA => 'Neto anual A';
  @override String get annualNetB => 'Neto anual B';
  @override String get effectiveRate => 'Tasa efectiva';
  @override String get totalComp => 'Comp. total';

  // ── Negotiation tips ──────────────────────────────────────────────────────────
  @override String get negotiationTips => 'Consejos de Negociación';
  @override String get offerGap => 'Brecha entre ofertas';
  @override String get alsoConsider =>
      'También considera: PTO extra, trabajo remoto, bono de firma o revisión salarial a 6 meses.';

  // ── Break-even ────────────────────────────────────────────────────────────────
  @override String get breakEvenAnalysis => 'Punto de equilibrio';
  @override String get months => 'meses';
  @override String get years1 => '1 año';
  @override String get yearsN => 'años';

  // ── Wealth building ───────────────────────────────────────────────────────────
  @override String get wealthBuilding => 'Construcción de riqueza';
  @override String get totalEarnings5Years => 'Compensación total — 5 años';
  @override String get cumulativeWithRaises => 'Suma acumulada con aumentos anuales';
  @override String get k401kRetirement30yr => '401k a la jubilación (30 años)';
  @override String get contrib6PctMatch7Pct => '6% aporte + match · 7% retorno compuesto';
  @override String get netInvestableWealth5Yr => 'Riqueza neta en 5 años';
  @override String get savings20Pct6PctReturn => '20% tasa de ahorro · 6% retorno anual';
  @override String get wealthDisclaimer =>
      '* Proyecciones estimativas basadas en tasas 2025. La rentabilidad real puede variar.';

  // ── Projection ────────────────────────────────────────────────────────────────
  @override String get projection5Year => 'Proyección 5 Años';
  @override String get total5Years => 'TOTAL 5 años';

  // ── RSU vesting ───────────────────────────────────────────────────────────────
  @override String get totalGrantA => 'Total concesión A';
  @override String get totalGrantB => 'Total concesión B';
  @override String get totalGrantC => 'Total concesión C';
  @override String get vestYear => 'Año';
  @override String get grossVest => 'Vest bruto';
  @override String get netEst => 'Neto (est.)';
  @override String get progress => 'Progreso';
  @override String get offerALabel2 => 'Oferta A';
  @override String get offerBLabel2 => 'Oferta B';
  @override String get offerCLabel2 => 'Oferta C';
  @override String get rsuDisclaimer =>
      'Las RSU se gravan como ingreso ordinario en la fecha de adquisición. Los valores mostrados son estimaciones previas a impuestos. El valor real depende del precio de la acción al momento de la adquisición.';
  @override String get year1Cliff => 'Año 1 (cliff)';
  @override String get taxEst => 'imp. est.';

  // ── Benchmark callout ─────────────────────────────────────────────────────────
  @override String get bls2025Prefix => 'BLS 2025 — ';

  // ── Winner banner ─────────────────────────────────────────────────────────────
  @override String get offerAWinsTitle => 'Oferta A gana';
  @override String get offerBWinsTitle => 'Oferta B gana';
  @override String get offerCWinsTitle => 'Oferta C gana';
  @override String get morePerYearNet => 'más al año en compensación neta';
  @override String get itsATie => 'Empate perfecto';
  @override String get bothOffersNearlyEqual =>
      'Ambas ofertas son prácticamente iguales en compensación total';

  // ── History screen ────────────────────────────────────────────────────────────
  @override String get savedOffers => 'Ofertas Guardadas';
  @override String get clearAll => 'Borrar todo';
  @override String get noSavedOffers => 'No hay ofertas guardadas';
  @override String get noSavedOffersBody =>
      'Guarda tu primera comparación para verla aquí';
  @override String get compareNow => 'Comparar ahora';
  @override String get savedScenarios => 'ESCENARIOS GUARDADOS';
  @override String get recentComparisons => 'COMPARACIONES RECIENTES';
  @override String get saved => 'guardadas';
  @override String get maxRecentPinned => 'Máx \${MonetizationConfig.freeRingBufferSize} recientes · \${MonetizationConfig.freePinnedLimit} guardados';
  @override String get unlock => 'Desbloquear';
  @override String get offerLabel => 'Oferta';
  @override String get perMonth => '/mes';
  @override String get tax => 'Imp.';
  @override String get netPerYear => 'neto/año';
  @override String get unpin => 'Quitar';
  @override String get rename => 'Renombrar';
  @override String get delete => 'Eliminar';
  @override String get failedToDelete => 'Error al eliminar';
  @override String get failedToClear => 'Error al borrar';
  @override String get renameScenario => 'Renombrar escenario';
  @override String get scenarioName => 'Nombre del escenario';
  @override String get deleteOffer => '¿Eliminar oferta?';
  @override String get deleteOfferBody =>
      'Esta entrada será eliminada permanentemente del historial.';
  @override String get clearAllTitle => '¿Borrar todo?';
  @override String get clearAllBody => '¿Eliminar todo el historial?';
  @override String get clear => 'Borrar';

  // ── History detail ─────────────────────────────────────────────────────────────
  @override String get savedComparison => 'Comparación guardada';
  @override String get offerDetail => 'Detalle de Oferta';
  @override String get failedExportPdfLabel => 'Error al exportar PDF';
  @override String get generating => 'Generando...';
  @override String get exportFullPdfReport => 'Exportar reporte completo PDF';
  @override String get detailedPdfPremium => 'PDF detallado — Premium';
  @override String get pages5TaxesBenefitsProjection =>
      '5 páginas · Impuestos · Beneficios · Proyección 5 años';
  @override String get savedLabel => 'Guardado';
  @override String get advantagePerYear => 'ventaja/año';
  @override String get netsPerYear => 'neto/año';
  @override String get netPerMonth2 => '/mes';
  @override String get taxLabel => 'imp.';
  @override String get winnerLabel => 'gana';
  @override String get ganadorLabel => 'Ganador';
  @override String get categoryWinners => 'Ganadores por categoría';
  @override String get income => 'Ingresos';
  @override String get annualNet => 'Neto anual';
  @override String get monthlyNet2 => 'Neto mensual';
  @override String get totalNetComp => 'Comp. total neta';
  @override String get taxes => 'Impuestos';
  @override String get effectiveRate2 => 'Tasa efectiva';
  @override String get federal => 'Federal';
  @override String get stateLabel2 => 'Estatal';
  @override String get totalTaxes => 'Total impuestos';
  @override String get bonuses => 'Bonos';
  @override String get annualBonusGross => 'Bono anual (bruto)';
  @override String get annualBonusAfterTax2 => 'Bono anual (neto)';
  @override String get signingBonusAfterTax2 => 'Bono contratación (neto)';
  @override String get benefitsLabel => 'Beneficios';
  @override String get match401kLabel => 'Match 401k';
  @override String get healthDental => 'Salud / Dental';
  @override String get ptoValueLabel2 => 'valor';
  @override String get commuteLabel => 'Costo traslado';
  @override String get purchasingPower => 'Poder adquisitivo';
  @override String get colAdjustedTakeHome2 => 'Neto ajustado (costo de vida)';
  @override String get projection5Yr => 'Proyección 5 años';
  @override String get compensation => 'Compensación';
  @override String get grossSalaryLabel => 'Salario bruto';
  @override String get netAnnualLabel => 'Ingreso neto anual';
  @override String get netMonthlyLabel => 'Ingreso neto mensual';
  @override String get bonusLabel => 'Bono';
  @override String get effectiveTaxRateLabel2 => 'Tasa impositiva';
  @override String get exportPdfLabel => 'Exportar PDF';
  @override String get cityLabel => 'Ciudad';
  @override String get ptoLabel => 'Días PTO';
  @override String get daysLabel => 'días';
  @override String get benefitsExtras => 'Beneficios y Extras';

  // ── Settings ───────────────────────────────────────────────────────────────────
  @override String get settings => 'Ajustes';
  @override String get youArePremium => '¡Eres Premium!';
  @override String get getPremium => 'Obtener Premium';
  @override String get restorePurchase => 'Restaurar compra';
  @override String get language => 'Idioma';
  @override String get appearance => 'Apariencia';
  @override String get more => 'Más';
  @override String get privacyPolicy => 'Política de privacidad';
  @override String get rateTheApp => 'Calificar la app';
  @override String get contactSupport => 'Contactar soporte';
  @override String get moreAppsByCalqWise => 'Más apps de CalqWise';
  @override String get settingsDisclaimer =>
      'Esta aplicación es solo para fines informativos. Consulte a un profesional financiero antes de tomar decisiones laborales o de compensación.';

  // ── Save scenario button ───────────────────────────────────────────────────────
  @override String get saveScenario => 'Guardar escenario';
  @override String get saving => 'Guardando…';
  @override String get scenarioNameOptional => 'Nombre del escenario (opcional)';
  @override String get scenarioSavedWithLabel => 'Escenario guardado';
  @override String get saveScenarioTitle => 'Guardar escenario';

  // ── Offer parser dialog ────────────────────────────────────────────────────────
  @override String get parseOfferLetter => 'Analizar carta de oferta';
  @override String get parseOfferHint =>
      'Pega el texto de tu oferta. Detectaremos salario, bono, equity y más.';
  @override String get pasteOfferHere => 'Pega aquí el texto de la oferta…';
  @override String get freeLimitReached =>
      'Límite gratuito: 3 análisis por día. Premium para ilimitado.';
  @override String get noDataFound =>
      'No se encontraron datos. Pega más contexto.';
  @override String get fieldsDetected => 'campos detectados';
  @override String get baseSalaryLabel => 'Salario base';
  @override String get signOnBonusLabel => 'Bono de firma';
  @override String get annualBonusLabel => 'Bono anual';
  @override String get equityRsuLabel => 'Equity / RSU';
  @override String get ptoDaysLabel => 'Días PTO';
  @override String get titleLabel => 'Puesto';
  @override String get companyLabel => 'Empresa';
  @override String get parse => 'Analizar';
  @override String get fillForm => 'Rellenar';

  // ── Paywall ───────────────────────────────────────────────────────────────────
  @override String get unlockLabel => 'Desbloquear';

  // ── Dynamic ───────────────────────────────────────────────────────────────────
  @override String yearN(int n) => 'Año $n';
  @override String yearNCliff(int n) => 'Año $n (cliff)';
  @override String monthsDuration(int n) => '$n meses';
  @override String yearsDuration(int n) => '$n ${n == 1 ? "año" : "años"}';
  @override String yearsMonthsDuration(int yr, int rem) => '$yr a. $rem m.';
  @override String overtakes(String winner, String loser) =>
      '→ $winner supera a $loser';
  @override String breakEvenBody(String loser, String winner, String duration) =>
      '$loser tiene ventaja de bono inicial. Pero $winner paga más cada año — después de $duration, $winner habrá ganado más en total.';
  @override String counterOffer(String loserLabel, String targetAmount) =>
      'Si está negociando $loserLabel, pida $targetAmount neto anual para dividir la diferencia a la mitad.';
  @override String scenarioSavedNamed(String label) =>
      'Escenario "$label" guardado';
  @override String aboveBenchmark(String state, int medianK, int absDiff) =>
      '+$absDiff% sobre la mediana estatal ($state \$${medianK}k)';
  @override String belowBenchmark(String state, int medianK, int absDiff) =>
      '${absDiff}% bajo la mediana estatal ($state \$${medianK}k)';
  @override String nearBenchmark(String state, int medianK, String pctStr) =>
      'Cerca de la mediana estatal ($state \$${medianK}k, $pctStr%)';
  @override String benchmarkChipAbove(String state, int medianK, int absDiff) =>
      '📊 $state mediana: \$${medianK}k — $absDiff% sobre el mercado';
  @override String benchmarkChipBelow(String state, int medianK, int absDiff) =>
      '📊 $state mediana: \$${medianK}k — $absDiff% bajo el mercado';
  @override String benchmarkChipAt(String state, int medianK) =>
      '📊 $state mediana: \$${medianK}k — en el mercado';
  @override String winnerAnnualNetLabel(String winnerLabel) =>
      '$winnerLabel — Neto anual';
  @override String winnerAdvantage(String amount) =>
      'Ventaja: $amount/año';
  @override String semanticsWinnerKpi(
          String winnerLabel, String netAmount, String advantage) =>
      '$winnerLabel gana con $netAmount neto anual, ventaja de $advantage';
  @override String semanticsEquivalent(String totalComp) =>
      'Las dos ofertas son equivalentes. Compensación total: $totalComp';
  @override String winnerLabelA(String winnerLabel) => winnerLabel;
  @override String winnerLabelB(String winnerLabel) => winnerLabel;
  @override String winnerSemanticsLabel(
          String winnerLabel, String netAmount, String advantage) =>
      '$winnerLabel gana con $netAmount neto anual, ventaja de $advantage';
  @override String winnerPerYrPerMo(String advStr, String perMo) =>
      '+$advStr/año · \$$perMo/mes';

  // ── Insight engine ─────────────────────────────────────────────────────────
  @override String insightLowerTaxTitle(String lower) =>
      'Carga fiscal más baja en Oferta $lower';
  @override String insightLowerTaxBody(String lower, String diff, String higher) =>
      'Oferta $lower tiene $diff% menos de impuestos efectivos que Oferta $higher. El estado importa.';
  @override String insightCommuteTitle(String cheaper) =>
      'Oferta $cheaper ahorra en desplazamiento';
  @override String insightCommuteBody(String diff) =>
      '\$$diff/año de diferencia en costos de transporte.';
  @override String insightRemoteTitle(String remote) =>
      'Oferta $remote es remota — ventaja oculta';
  @override String insightRemoteBody() =>
      'El trabajo remoto elimina costos de transporte y puede compensar una diferencia salarial de \$3k–\$8k.';
  @override String insightBetter401kTitle(String better) =>
      '401k más generoso en Oferta $better';
  @override String insightBetter401kBody(String better, String diff, String worse) =>
      'Oferta $better aporta \$$diff/año más en tu jubilación que Oferta $worse.';
  @override String insightColFlipsTitle() =>
      'Costo de vida invierte el resultado';
  @override String insightColFlipsBody(String rawWinner, String colWinner) =>
      'Oferta $rawWinner paga más en papel, pero Oferta $colWinner da más poder adquisitivo real en esa ciudad.';
  @override String insightMoreEquityTitle(String better) =>
      'Oferta $better tiene más equity';
  @override String insightMoreEquityBody(String diff) =>
      '\$$diff/año de diferencia en RSU/stock. Verifica el vesting schedule.';
  @override String insightBetter5yrTitle(String better) =>
      'Oferta $better vale más a 5 años';
  @override String insightBetter5yrBody(String diff) =>
      '\$${diff}k de diferencia en compensación total proyectada a 5 años.';
  @override String insightHighTaxTitle(String offer) =>
      'Alta carga fiscal en Oferta $offer';
  @override String insightHighTaxBody(String pct) =>
      'Pagarás $pct% en impuestos. El sueldo bruto puede ser engañoso.';
  @override String insightMorePtoTitle(String better) =>
      'Más días libres en Oferta $better';
  @override String insightMorePtoBody(String diff) =>
      'La diferencia en días libres vale ~\$$diff/año.';
  @override String insightOffersCloseTitle() =>
      'Ofertas muy similares';
  @override String insightOffersCloseBody() =>
      'Los números son similares. Considera factores no financieros: cultura, potencial de crecimiento, estabilidad.';
}
