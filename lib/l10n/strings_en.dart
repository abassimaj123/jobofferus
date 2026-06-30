// lib/l10n/strings_en.dart
// Abstract base + English implementation for all app-level UI strings.
// Usage: final s = isSpanish ? const AppStringsEs() : const AppStringsEn();

abstract class AppStrings {
  // ── App ──────────────────────────────────────────────────────────────────────
  String get appTitle;

  // ── Home / ComparisonTab ─────────────────────────────────────────────────────
  String get compareOffers;
  String get compare;
  String get history;
  String get pleaseFixErrors;

  // ── Hero banner ───────────────────────────────────────────────────────────────
  String get heroTitle;
  String get heroSubtitle;
  String get heroChip51States;
  String get heroChip3Offers;

  // ── Add / Remove offer C chips ────────────────────────────────────────────────
  String get add3rdOffer;
  String get remove3rdOffer;

  // ── Offer form card ───────────────────────────────────────────────────────────
  String get offerA;
  String get offerB;
  String get offerC;
  String get offerName;
  String get company;
  String get pasteOfferLetter;
  String get newBadge;
  String get annual;
  String get hourly;
  String get hourlySalaryLabel;
  String get annualSalaryLabel;
  String get hrsWeek;
  String get bonusPct;
  String get ptoDays;
  String get signingBonus;
  String get upTo;
  String get healthPerYr;
  String get dentalPerYr;
  String get annualRsuStock;
  String get milesOneWayCommute;
  String get annualRaisePct;
  String get remoteWork;
  String get cityColLabel;
  String get state;
  String get noDeadline;
  String get offerDeadline;
  String get daysLeft;
  String get deadlineExpired;
  String get hidebenefits;
  String get benefitsAndCommute;
  String get benefits401kRsuHealth;
  // Benchmark chip
  String get median;
  String get aboveMarket;
  String get belowMarket;
  String get atMarket;
  // Validators
  String get required;
  String get invalidNumber;
  String get mustBeGte0;
  // Offer year label (hourly display suffix)
  String get perYear;

  // ── Comparison screen ─────────────────────────────────────────────────────────
  String get export;
  String get exportCsv;
  String get exportCsvSubtitle;
  String get exportPdf;
  String get exportPdfSubtitlePremium;
  String get exportPdfSubtitleLocked;
  String get cancel;
  String get pdfGenerated;
  String get failedExportPdf;
  String get failedExportCsv;
  String get scenarioSaved;
  String get failedSave;
  String get exportPdfReport;
  String get unlimitedSavedScenarios;
  String get unlimitedSavedScenariosSubtitle;
  String get realPurchasingPower;
  String get realPurchasingPowerByCity;
  String get colAdjustedTakeHome;
  String get nyc100kNeqDallas;
  String get longTermWealthAnalysis;
  String get longTermWealthSubtitle;
  String get scenarioSavedLabel;

  // ── CSV column headers ─────────────────────────────────────────────────────────
  String get field;
  String get grossSalary;
  String get city;
  String get stateLabel;
  String get netAnnualTakeHome;
  String get netMonthly;
  String get effectiveTaxRate;
  String get federalTax;
  String get stateTax;
  String get annualBonusAfterTax;
  String get signingBonusAfterTax;
  String get match401k;
  String get healthBenefits;
  String get ptoValue;
  String get annualRsu;
  String get commuteCost;
  String get totalNetCompensation;

  // ── PDF generation ─────────────────────────────────────────────────────────────
  String get pdfTitle;
  String get generated;
  String get pdfDisclaimer;
  String get metric;
  String get offerALabel;
  String get offerBLabel;
  String get offerCLabel;
  String get advantage;
  String get offerAWins;
  String get offerBWins;
  String get offerCWins;
  String get tie;

  // ── Comparison body sections ───────────────────────────────────────────────────
  String get afterTaxIncome;
  String get annualTakeHome;
  String get monthly;
  String get effectiveTaxRateLabel;
  String get taxBreakdown;
  String get federalTaxLabel;
  String get stateTaxLabel;
  String get cityLocalTax;
  String get benefitsAndExtras;
  String get annualBonusAfterTaxLabel;
  String get signingBonusAfterTaxLabel;
  String get k401kEmployerMatch;
  String get healthPlusDental;
  String get ptoValueLabel;
  String get annualRsuStock2;
  String get commuteCosMinus;
  String get rsuVestingSchedule;
  String get netTotalCompensation;
  String get totalAnnualNet;
  String get totalMonthlyNet;

  // ── Hero KPI card ──────────────────────────────────────────────────────────────
  String get totalCompensation;
  String get bothOffersEquivalent;
  String get annualNetA;
  String get annualNetB;
  String get effectiveRate;
  String get totalComp;

  // ── Negotiation tips ──────────────────────────────────────────────────────────
  String get negotiationTips;
  String get offerGap;
  String get alsoConsider;

  // ── Break-even card ───────────────────────────────────────────────────────────
  String get breakEvenAnalysis;
  String get months; // used in duration string
  String get years1; // '1 year'
  String get yearsN; // '$n years' — use yearsDyn

  // ── Wealth building card ───────────────────────────────────────────────────────
  String get wealthBuilding;
  String get totalEarnings5Years;
  String get cumulativeWithRaises;
  String get k401kRetirement30yr;
  String get contrib6PctMatch7Pct;
  String get netInvestableWealth5Yr;
  String get savings20Pct6PctReturn;
  String get wealthDisclaimer;

  // ── Projection card ───────────────────────────────────────────────────────────
  String get projection5Year;
  String get total5Years;

  // ── RSU vesting card ──────────────────────────────────────────────────────────
  String get totalGrantA;
  String get totalGrantB;
  String get totalGrantC;
  String get vestYear;
  String get grossVest;
  String get netEst;
  String get progress;
  String get offerALabel2;
  String get offerBLabel2;
  String get offerCLabel2;
  String get rsuDisclaimer;
  String get year1Cliff;
  String get taxEst;

  // ── Benchmark callout ─────────────────────────────────────────────────────────
  String get bls2025Prefix;

  // ── Winner banner ─────────────────────────────────────────────────────────────
  String get offerAWinsTitle;
  String get offerBWinsTitle;
  String get offerCWinsTitle;
  String get morePerYearNet;
  String get itsATie;
  String get bothOffersNearlyEqual;

  // ── History screen ─────────────────────────────────────────────────────────────
  String get savedOffers;
  String get clearAll;
  String get noSavedOffers;
  String get noSavedOffersBody;
  String get compareNow;
  String get savedScenarios;
  String get recentComparisons;
  String get saved; // used in count header
  String get maxRecentPinned;
  String get unlock;
  String get offerLabel; // fallback card title
  String get perMonth;
  String get tax;
  String get netPerYear;
  String get unpin;
  String get rename;
  String get delete;
  String get failedToDelete;
  String get failedToClear;
  String get renameScenario;
  String get scenarioName;
  String get deleteOffer;
  String get deleteOfferBody;
  String get clearAllTitle;
  String get clearAllBody;
  String get clear;

  // ── History detail screen ───────────────────────────────────────────────────────
  String get savedComparison;
  String get offerDetail;
  String get failedExportPdfLabel;
  String get generating;
  String get exportFullPdfReport;
  String get detailedPdfPremium;
  String get pages5TaxesBenefitsProjection;
  String get savedLabel;
  String get advantagePerYear;
  String get netsPerYear;
  String get netPerMonth2;
  String get taxLabel;
  String get winnerLabel;
  String get ganadorLabel;
  String get categoryWinners;
  String get income;
  String get annualNet;
  String get monthlyNet2;
  String get totalNetComp;
  String get taxes;
  String get effectiveRate2;
  String get federal;
  String get stateLabel2;
  String get totalTaxes;
  String get bonuses;
  String get annualBonusGross;
  String get annualBonusAfterTax2;
  String get signingBonusAfterTax2;
  String get benefitsLabel;
  String get match401kLabel;
  String get healthDental;
  String get ptoValueLabel2;
  String get commuteLabel;
  String get purchasingPower;
  String get colAdjustedTakeHome2;
  String get projection5Yr;
  String get compensation;
  String get grossSalaryLabel;
  String get netAnnualLabel;
  String get netMonthlyLabel;
  String get bonusLabel;
  String get effectiveTaxRateLabel2;
  String get exportPdfLabel;
  String get cityLabel;
  String get ptoLabel;
  String get daysLabel;
  String get benefitsExtras;

  // ── Settings screen ────────────────────────────────────────────────────────────
  String get settings;
  String get youArePremium;
  String get getPremium;
  String get restorePurchase;
  String get language;
  String get appearance;
  String get more;
  String get privacyPolicy;
  String get rateTheApp;
  String get contactSupport;
  String get moreAppsByCalqWise;
  String get settingsDisclaimer;

  // ── Save scenario button ───────────────────────────────────────────────────────
  String get saveScenario;
  String get saving;
  String get scenarioNameOptional;
  String get scenarioSavedWithLabel;
  String get saveScenarioTitle;

  // ── Offer parser dialog ────────────────────────────────────────────────────────
  String get parseOfferLetter;
  String get parseOfferHint;
  String get pasteOfferHere;
  String get freeLimitReached;
  String get noDataFound;
  String get fieldsDetected;
  String get baseSalaryLabel;
  String get signOnBonusLabel;
  String get annualBonusLabel;
  String get equityRsuLabel;
  String get ptoDaysLabel;
  String get titleLabel;
  String get companyLabel;
  String get parse;
  String get fillForm;

  // ── Paywall (soft) ─────────────────────────────────────────────────────────────
  String get unlockLabel;

  // ── Dynamic methods ────────────────────────────────────────────────────────────
  String yearN(int n);
  String yearNCliff(int n);
  String monthsDuration(int n);
  String yearsDuration(int n);
  String yearsMonthsDuration(int yr, int rem);
  String overtakes(String winner, String loser);
  String breakEvenBody(String loser, String winner, String duration);
  String counterOffer(String loserLabel, String targetAmount);
  String scenarioSavedNamed(String label);
  String aboveBenchmark(String state, int medianK, int absDiff);
  String belowBenchmark(String state, int medianK, int absDiff);
  String nearBenchmark(String state, int medianK, String pctStr);
  String benchmarkChipAbove(String state, int medianK, int absDiff);
  String benchmarkChipBelow(String state, int medianK, int absDiff);
  String benchmarkChipAt(String state, int medianK);
  String winnerAnnualNetLabel(String winnerLabel);
  String winnerAdvantage(String amount);
  String semanticsWinnerKpi(String winnerLabel, String netAmount, String advantage);
  String semanticsEquivalent(String totalComp);
  String winnerLabelA(String winnerLabel);
  String winnerLabelB(String winnerLabel);
  String winnerSemanticsLabel(String winnerLabel, String netAmount, String advantage);
  String winnerPerYrPerMo(String advStr, String perMo);

  // ── Insight engine ─────────────────────────────────────────────────────────
  String insightLowerTaxTitle(String lower);
  String insightLowerTaxBody(String lower, String diff, String higher);
  String insightCommuteTitle(String cheaper);
  String insightCommuteBody(String diff);
  String insightRemoteTitle(String remote);
  String insightRemoteBody();
  String insightBetter401kTitle(String better);
  String insightBetter401kBody(String better, String diff, String worse);
  String insightColFlipsTitle();
  String insightColFlipsBody(String rawWinner, String colWinner);
  String insightMoreEquityTitle(String better);
  String insightMoreEquityBody(String diff);
  String insightBetter5yrTitle(String better);
  String insightBetter5yrBody(String diff);
  String insightHighTaxTitle(String offer);
  String insightHighTaxBody(String pct);
  String insightMorePtoTitle(String better);
  String insightMorePtoBody(String diff);
  String insightOffersCloseTitle();
  String insightOffersCloseBody();
}

class AppStringsEn implements AppStrings {
  const AppStringsEn();

  @override String get appTitle => 'Job Offer US';

  // ── Home ─────────────────────────────────────────────────────────────────────
  @override String get compareOffers => 'Compare Offers';
  @override String get compare => 'Compare';
  @override String get history => 'History';
  @override String get pleaseFixErrors => 'Please fix errors before comparing';

  // ── Hero ──────────────────────────────────────────────────────────────────────
  @override String get heroTitle => 'Know your true compensation';
  @override String get heroSubtitle => 'After-tax salary, benefits, commute & more';
  @override String get heroChip51States => '51 States';
  @override String get heroChip3Offers => '3 Offers';

  // ── Add / Remove offer C ──────────────────────────────────────────────────────
  @override String get add3rdOffer => 'Add 3rd offer';
  @override String get remove3rdOffer => 'Remove 3rd offer';

  // ── Offer form card ───────────────────────────────────────────────────────────
  @override String get offerA => 'Offer A';
  @override String get offerB => 'Offer B';
  @override String get offerC => 'Offer C';
  @override String get offerName => 'Offer name';
  @override String get company => 'Company';
  @override String get pasteOfferLetter => 'Paste offer letter';
  @override String get newBadge => 'NEW';
  @override String get annual => 'Annual';
  @override String get hourly => 'Hourly';
  @override String get hourlySalaryLabel => 'Hourly rate (\$)';
  @override String get annualSalaryLabel => 'Annual salary (\$)';
  @override String get hrsWeek => 'hrs/week';
  @override String get bonusPct => 'Bonus (%)';
  @override String get ptoDays => 'PTO days';
  @override String get signingBonus => 'Signing Bonus (\$)';
  @override String get upTo => 'Up to (%)';
  @override String get healthPerYr => 'Health (\$/yr)';
  @override String get dentalPerYr => 'Dental (\$/yr)';
  @override String get annualRsuStock => 'Annual RSU/Stock (\$)';
  @override String get milesOneWayCommute => 'Miles one-way commute';
  @override String get annualRaisePct => 'Annual raise (%)';
  @override String get remoteWork => 'Remote work';
  @override String get cityColLabel => 'City (cost of living)';
  @override String get state => 'State';
  @override String get noDeadline => 'No deadline';
  @override String get offerDeadline => 'Offer deadline:';
  @override String get daysLeft => 'days left';
  @override String get deadlineExpired => 'Expired';
  @override String get hidebenefits => 'Hide benefits';
  @override String get benefitsAndCommute => '+ Benefits & commute';
  @override String get benefits401kRsuHealth => '401k · RSU · Health';
  @override String get median => 'median';
  @override String get aboveMarket => 'above market';
  @override String get belowMarket => 'below market';
  @override String get atMarket => 'at market';
  @override String get required => 'Required';
  @override String get invalidNumber => 'Invalid number';
  @override String get mustBeGte0 => 'Must be ≥ 0';
  @override String get perYear => '/yr';

  // ── Comparison screen ─────────────────────────────────────────────────────────
  @override String get export => 'Export';
  @override String get exportCsv => 'Export CSV';
  @override String get exportCsvSubtitle => 'Open in Excel or Sheets';
  @override String get exportPdf => 'Export PDF';
  @override String get exportPdfSubtitlePremium => 'Full report';
  @override String get exportPdfSubtitleLocked => 'Premium — unlock';
  @override String get cancel => 'Cancel';
  @override String get pdfGenerated => 'PDF generated ✓';
  @override String get failedExportPdf => 'Failed to export PDF';
  @override String get failedExportCsv => 'Failed to export CSV';
  @override String get scenarioSaved => 'Scenario saved';
  @override String get failedSave => 'Failed to save';
  @override String get exportPdfReport => 'Export PDF Report';
  @override String get unlimitedSavedScenarios => 'Unlimited saved scenarios';
  @override String get unlimitedSavedScenariosSubtitle =>
      'Save and name all your comparisons without limit';
  @override String get realPurchasingPower => 'Real Purchasing Power (CoL-adjusted)';
  @override String get realPurchasingPowerByCity => 'Real purchasing power by city';
  @override String get colAdjustedTakeHome => 'CoL-adjusted take-home';
  @override String get nyc100kNeqDallas => '\$100k in NYC ≠ \$100k in Dallas';
  @override String get longTermWealthAnalysis => 'Long-term wealth analysis';
  @override String get longTermWealthSubtitle =>
      '5-year projection · 401k at retirement · Net wealth · Break-even';
  @override String get scenarioSavedLabel => 'Scenario saved';

  // ── CSV headers ───────────────────────────────────────────────────────────────
  @override String get field => 'Field';
  @override String get grossSalary => 'Gross Salary';
  @override String get city => 'City';
  @override String get stateLabel => 'State';
  @override String get netAnnualTakeHome => 'Net Annual Take-Home';
  @override String get netMonthly => 'Net Monthly';
  @override String get effectiveTaxRate => 'Effective Tax Rate';
  @override String get federalTax => 'Federal Tax';
  @override String get stateTax => 'State Tax';
  @override String get annualBonusAfterTax => 'Annual Bonus (after tax)';
  @override String get signingBonusAfterTax => 'Signing Bonus (after tax)';
  @override String get match401k => '401k Match';
  @override String get healthBenefits => 'Health Benefits';
  @override String get ptoValue => 'PTO Value';
  @override String get annualRsu => 'Annual RSU';
  @override String get commuteCost => 'Commute Cost';
  @override String get totalNetCompensation => 'Total Net Compensation';

  // ── PDF ───────────────────────────────────────────────────────────────────────
  @override String get pdfTitle => 'Job Offer Comparison';
  @override String get generated => 'Generated';
  @override String get pdfDisclaimer =>
      'Disclaimer: This report is for informational purposes only. Consult a tax professional.';
  @override String get metric => 'Metric';
  @override String get offerALabel => 'Offer A';
  @override String get offerBLabel => 'Offer B';
  @override String get offerCLabel => 'Offer C';
  @override String get advantage => 'advantage';
  @override String get offerAWins => 'Offer A wins';
  @override String get offerBWins => 'Offer B wins';
  @override String get offerCWins => 'Offer C wins';
  @override String get tie => 'Tie';

  // ── Comparison sections ────────────────────────────────────────────────────────
  @override String get afterTaxIncome => 'After-Tax Income';
  @override String get annualTakeHome => 'Annual take-home';
  @override String get monthly => 'Monthly';
  @override String get effectiveTaxRateLabel => 'Effective tax rate';
  @override String get taxBreakdown => 'Tax Breakdown';
  @override String get federalTaxLabel => 'Federal tax';
  @override String get stateTaxLabel => 'State tax';
  @override String get cityLocalTax => 'City/local tax';
  @override String get benefitsAndExtras => 'Benefits & Extras';
  @override String get annualBonusAfterTaxLabel => 'Annual bonus (after tax)';
  @override String get signingBonusAfterTaxLabel => 'Signing bonus (after tax)';
  @override String get k401kEmployerMatch => '401k employer match';
  @override String get healthPlusDental => 'Health + dental';
  @override String get ptoValueLabel => 'PTO value';
  @override String get annualRsuStock2 => 'Annual RSU / Stock';
  @override String get commuteCosMinus => 'Commute cost (−)';
  @override String get rsuVestingSchedule => 'RSU Vesting Schedule';
  @override String get netTotalCompensation => 'Net Total Compensation';
  @override String get totalAnnualNet => 'Total annual net';
  @override String get totalMonthlyNet => 'Total monthly net';

  // ── Hero KPI ──────────────────────────────────────────────────────────────────
  @override String get totalCompensation => 'Total Compensation';
  @override String get bothOffersEquivalent => 'Both offers are equivalent';
  @override String get annualNetA => 'Annual net A';
  @override String get annualNetB => 'Annual net B';
  @override String get effectiveRate => 'Effective rate';
  @override String get totalComp => 'Total comp';

  // ── Negotiation tips ──────────────────────────────────────────────────────────
  @override String get negotiationTips => 'Negotiation Tips';
  @override String get offerGap => 'Offer gap';
  @override String get alsoConsider =>
      'Also consider: extra PTO, remote work, signing bonus, or a 6-month salary review.';

  // ── Break-even ────────────────────────────────────────────────────────────────
  @override String get breakEvenAnalysis => 'Break-even analysis';
  @override String get months => 'months';
  @override String get years1 => '1 year';
  @override String get yearsN => 'years';

  // ── Wealth building ───────────────────────────────────────────────────────────
  @override String get wealthBuilding => 'Wealth Building';
  @override String get totalEarnings5Years => 'Total Earnings — 5 Years';
  @override String get cumulativeWithRaises => 'Cumulative total with annual raises';
  @override String get k401kRetirement30yr => '401k Balance at Retirement (30 yr)';
  @override String get contrib6PctMatch7Pct => '6% contrib + match · 7% compounded return';
  @override String get netInvestableWealth5Yr => 'Net Investable Wealth — 5 Years';
  @override String get savings20Pct6PctReturn => '20% savings rate · 6% annual return';
  @override String get wealthDisclaimer =>
      '* Projections are estimates based on 2026 rates. Actual returns may vary.';

  // ── Projection ────────────────────────────────────────────────────────────────
  @override String get projection5Year => '5-Year Projection';
  @override String get total5Years => 'TOTAL 5 years';

  // ── RSU vesting ───────────────────────────────────────────────────────────────
  @override String get totalGrantA => 'Total grant A';
  @override String get totalGrantB => 'Total grant B';
  @override String get totalGrantC => 'Total grant C';
  @override String get vestYear => 'Year';
  @override String get grossVest => 'Gross vest';
  @override String get netEst => 'Net (est.)';
  @override String get progress => 'Progress';
  @override String get offerALabel2 => 'Offer A';
  @override String get offerBLabel2 => 'Offer B';
  @override String get offerCLabel2 => 'Offer C';
  @override String get rsuDisclaimer =>
      'RSU values shown are pre-tax estimates. Actual vesting value depends on stock price at vesting date. RSUs are taxed as ordinary income.';
  @override String get year1Cliff => 'Year 1 (cliff)';
  @override String get taxEst => 'tax est.';

  // ── Benchmark callout ─────────────────────────────────────────────────────────
  @override String get bls2025Prefix => 'BLS 2025 — ';

  // ── Winner banner ─────────────────────────────────────────────────────────────
  @override String get offerAWinsTitle => 'Offer A Wins';
  @override String get offerBWinsTitle => 'Offer B Wins';
  @override String get offerCWinsTitle => 'Offer C Wins';
  @override String get morePerYearNet => 'more per year in net total comp';
  @override String get itsATie => "It's a Tie!";
  @override String get bothOffersNearlyEqual => 'Both offers are nearly equal in total comp';

  // ── History screen ────────────────────────────────────────────────────────────
  @override String get savedOffers => 'Saved Offers';
  @override String get clearAll => 'Clear all';
  @override String get noSavedOffers => 'No saved offers';
  @override String get noSavedOffersBody =>
      'Save your first comparison to see it here';
  @override String get compareNow => 'Compare Now';
  @override String get savedScenarios => 'SAVED SCENARIOS';
  @override String get recentComparisons => 'RECENT COMPARISONS';
  @override String get saved => 'saved';
  @override String get maxRecentPinned => 'Max \${MonetizationConfig.freeRingBufferSize} recent · \${MonetizationConfig.freePinnedLimit} pinned';
  @override String get unlock => 'Unlock';
  @override String get offerLabel => 'Offer';
  @override String get perMonth => '/mo';
  @override String get tax => 'Tax';
  @override String get netPerYear => 'net/yr';
  @override String get unpin => 'Unpin';
  @override String get rename => 'Rename';
  @override String get delete => 'Delete';
  @override String get failedToDelete => 'Failed to delete';
  @override String get failedToClear => 'Failed to clear';
  @override String get renameScenario => 'Rename scenario';
  @override String get scenarioName => 'Scenario name';
  @override String get deleteOffer => 'Delete offer?';
  @override String get deleteOfferBody =>
      'This entry will be permanently removed from history.';
  @override String get clearAllTitle => 'Clear all?';
  @override String get clearAllBody => 'Delete all saved offers?';
  @override String get clear => 'Clear';

  // ── History detail ─────────────────────────────────────────────────────────────
  @override String get savedComparison => 'Saved Comparison';
  @override String get offerDetail => 'Offer Detail';
  @override String get failedExportPdfLabel => 'PDF export failed';
  @override String get generating => 'Generating...';
  @override String get exportFullPdfReport => 'Export Full PDF Report';
  @override String get detailedPdfPremium => 'Detailed PDF — Premium';
  @override String get pages5TaxesBenefitsProjection =>
      '5 pages · Taxes · Benefits · 5-Year Projection';
  @override String get savedLabel => 'Saved';
  @override String get advantagePerYear => 'advantage/yr';
  @override String get netsPerYear => 'net/yr';
  @override String get netPerMonth2 => '/mo';
  @override String get taxLabel => 'tax';
  @override String get winnerLabel => 'wins';
  @override String get ganadorLabel => 'Winner';
  @override String get categoryWinners => 'Category Winners';
  @override String get income => 'Income';
  @override String get annualNet => 'Annual Net Take-Home';
  @override String get monthlyNet2 => 'Monthly Net';
  @override String get totalNetComp => 'Total Net Comp.';
  @override String get taxes => 'Taxes';
  @override String get effectiveRate2 => 'Effective Rate';
  @override String get federal => 'Federal Tax';
  @override String get stateLabel2 => 'State Tax';
  @override String get totalTaxes => 'Total Taxes';
  @override String get bonuses => 'Bonuses';
  @override String get annualBonusGross => 'Annual Bonus (gross)';
  @override String get annualBonusAfterTax2 => 'Annual Bonus (after tax)';
  @override String get signingBonusAfterTax2 => 'Signing Bonus (after tax)';
  @override String get benefitsLabel => 'Benefits';
  @override String get match401kLabel => '401k Employer Match';
  @override String get healthDental => 'Health & Dental';
  @override String get ptoValueLabel2 => 'value';
  @override String get commuteLabel => 'Commute Cost';
  @override String get purchasingPower => 'Purchasing Power';
  @override String get colAdjustedTakeHome2 => 'CoL-Adjusted Take-Home';
  @override String get projection5Yr => '5-Year Projection';
  @override String get compensation => 'Compensation';
  @override String get grossSalaryLabel => 'Gross Salary';
  @override String get netAnnualLabel => 'Net Annual';
  @override String get netMonthlyLabel => 'Net Monthly';
  @override String get bonusLabel => 'Bonus';
  @override String get effectiveTaxRateLabel2 => 'Effective Tax Rate';
  @override String get exportPdfLabel => 'Export PDF';
  @override String get cityLabel => 'City';
  @override String get ptoLabel => 'PTO Days';
  @override String get daysLabel => 'days';
  @override String get benefitsExtras => 'Benefits & Extras';

  // ── Settings ───────────────────────────────────────────────────────────────────
  @override String get settings => 'Settings';
  @override String get youArePremium => "You're Premium!";
  @override String get getPremium => 'Get Premium';
  @override String get restorePurchase => 'Restore Purchase';
  @override String get language => 'Language';
  @override String get appearance => 'Appearance';
  @override String get more => 'More';
  @override String get privacyPolicy => 'Privacy Policy';
  @override String get rateTheApp => 'Rate the App';
  @override String get contactSupport => 'Contact Support';
  @override String get moreAppsByCalqWise => 'More apps by CalqWise';
  @override String get settingsDisclaimer =>
      'This app is for informational purposes only. Consult a financial professional before making any career or compensation decisions.';

  // ── Save scenario button ───────────────────────────────────────────────────────
  @override String get saveScenario => 'Save Scenario';
  @override String get saving => 'Saving…';
  @override String get scenarioNameOptional => 'Scenario name (optional)';
  @override String get scenarioSavedWithLabel => 'Scenario saved';
  @override String get saveScenarioTitle => 'Save Scenario';

  // ── Offer parser dialog ────────────────────────────────────────────────────────
  @override String get parseOfferLetter => 'Parse Offer Letter';
  @override String get parseOfferHint =>
      'Paste your offer text. We will detect salary, bonus, equity, and more.';
  @override String get pasteOfferHere => 'Paste offer letter text here…';
  @override String get freeLimitReached =>
      'Free limit: 3 parses per day. Premium for unlimited.';
  @override String get noDataFound => 'No data found. Paste more of the letter.';
  @override String get fieldsDetected => 'fields detected';
  @override String get baseSalaryLabel => 'Base salary';
  @override String get signOnBonusLabel => 'Sign-on bonus';
  @override String get annualBonusLabel => 'Annual bonus';
  @override String get equityRsuLabel => 'Equity / RSU';
  @override String get ptoDaysLabel => 'PTO days';
  @override String get titleLabel => 'Title';
  @override String get companyLabel => 'Company';
  @override String get parse => 'Parse';
  @override String get fillForm => 'Fill Form';

  // ── Paywall ───────────────────────────────────────────────────────────────────
  @override String get unlockLabel => 'Unlock';

  // ── Dynamic ───────────────────────────────────────────────────────────────────
  @override String yearN(int n) => 'Year $n';
  @override String yearNCliff(int n) => 'Year $n (cliff)';
  @override String monthsDuration(int n) => '$n months';
  @override String yearsDuration(int n) => '$n ${n == 1 ? "year" : "years"}';
  @override String yearsMonthsDuration(int yr, int rem) => '${yr}y ${rem}m';
  @override String overtakes(String winner, String loser) =>
      '→ $winner overtakes $loser';
  @override String breakEvenBody(String loser, String winner, String duration) =>
      '$loser has a signing bonus head start. But $winner pays more each year — after $duration, $winner\'s cumulative earnings surpass $loser\'s.';
  @override String counterOffer(String loserLabel, String targetAmount) =>
      'If negotiating $loserLabel, counter at $targetAmount/yr net to split the difference.';
  @override String scenarioSavedNamed(String label) => 'Scenario "$label" saved';
  @override String aboveBenchmark(String state, int medianK, int absDiff) =>
      '+$absDiff% above $state state median (\$${medianK}k)';
  @override String belowBenchmark(String state, int medianK, int absDiff) =>
      '${absDiff}% below $state state median (\$${medianK}k)';
  @override String nearBenchmark(String state, int medianK, String pctStr) =>
      'Near $state state median (\$${medianK}k, $pctStr%)';
  @override String benchmarkChipAbove(String state, int medianK, int absDiff) =>
      '📊 $state median: \$${medianK}k — $absDiff% above market';
  @override String benchmarkChipBelow(String state, int medianK, int absDiff) =>
      '📊 $state median: \$${medianK}k — $absDiff% below market';
  @override String benchmarkChipAt(String state, int medianK) =>
      '📊 $state median: \$${medianK}k — at market';
  @override String winnerAnnualNetLabel(String winnerLabel) =>
      '$winnerLabel — Annual Net';
  @override String winnerAdvantage(String amount) =>
      'Advantage: $amount/yr';
  @override String semanticsWinnerKpi(
          String winnerLabel, String netAmount, String advantage) =>
      '$winnerLabel wins with $netAmount annual net, advantage of $advantage';
  @override String semanticsEquivalent(String totalComp) =>
      'Both offers are equivalent. Total compensation: $totalComp';
  @override String winnerLabelA(String winnerLabel) => winnerLabel;
  @override String winnerLabelB(String winnerLabel) => winnerLabel;
  @override String winnerSemanticsLabel(
          String winnerLabel, String netAmount, String advantage) =>
      '$winnerLabel wins with $netAmount annual net, advantage of $advantage';
  @override String winnerPerYrPerMo(String advStr, String perMo) =>
      '+$advStr/yr · \$$perMo/mo';

  // ── Insight engine ─────────────────────────────────────────────────────────
  @override String insightLowerTaxTitle(String lower) =>
      'Lower tax burden in Offer $lower';
  @override String insightLowerTaxBody(String lower, String diff, String higher) =>
      'Offer $lower has ${diff}% lower effective tax rate than Offer $higher. The state matters.';
  @override String insightCommuteTitle(String cheaper) =>
      'Offer $cheaper saves on commute';
  @override String insightCommuteBody(String diff) =>
      '\$$diff/yr difference in commute costs.';
  @override String insightRemoteTitle(String remote) =>
      'Offer $remote is remote — hidden advantage';
  @override String insightRemoteBody() =>
      'Remote work eliminates commute costs and can offset a \$3k–\$8k salary gap.';
  @override String insightBetter401kTitle(String better) =>
      'Better 401k match in Offer $better';
  @override String insightBetter401kBody(String better, String diff, String worse) =>
      'Offer $better contributes \$$diff/yr more to your retirement than Offer $worse.';
  @override String insightColFlipsTitle() =>
      'Cost of living flips the winner';
  @override String insightColFlipsBody(String rawWinner, String colWinner) =>
      'Offer $rawWinner pays more on paper, but Offer $colWinner gives more real purchasing power in that city.';
  @override String insightMoreEquityTitle(String better) =>
      'Offer $better has more equity';
  @override String insightMoreEquityBody(String diff) =>
      '\$$diff/yr difference in RSU/stock value. Check the vesting schedule.';
  @override String insightBetter5yrTitle(String better) =>
      'Offer $better is worth more over 5 years';
  @override String insightBetter5yrBody(String diff) =>
      '\$${diff}k difference in projected total comp over 5 years.';
  @override String insightHighTaxTitle(String offer) =>
      'High tax burden on Offer $offer';
  @override String insightHighTaxBody(String pct) =>
      "You'll pay $pct% in taxes. Gross salary can be misleading.";
  @override String insightMorePtoTitle(String better) =>
      'More PTO value in Offer $better';
  @override String insightMorePtoBody(String diff) =>
      'The PTO difference is worth ~\$$diff/yr.';
  @override String insightOffersCloseTitle() =>
      'These offers are very close';
  @override String insightOffersCloseBody() =>
      'The numbers are close. Consider non-financial factors: culture, growth potential, stability.';
}
