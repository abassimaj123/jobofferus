/// US state income tax brackets — 2025
/// Format: list of (upperBound, rate) pairs, progressive.
/// Final entry has upperBound = double.infinity (top bracket).
/// Source: state tax authority websites, 2025 rates.

typedef Bracket = (double upperBound, double rate);

class StateTaxData {
  StateTaxData._();

  /// Returns annual state income tax for [grossIncome] in [stateCode].
  static double calculate(double grossIncome, String stateCode) {
    final brackets = _brackets[stateCode.toUpperCase()];
    if (brackets == null) return 0; // unknown state → 0 (safe default)
    return _applyBrackets(grossIncome, brackets);
  }

  static double _applyBrackets(double income, List<Bracket> brackets) {
    double tax = 0;
    double remaining = income;
    double prev = 0;
    for (final (upper, rate) in brackets) {
      if (remaining <= 0) break;
      final chunk = upper == double.infinity
          ? remaining
          : (income > upper ? upper - prev : income - prev);
      if (chunk <= 0) {
        prev = upper;
        continue;
      }
      tax += chunk * rate;
      remaining -= chunk;
      prev = upper;
    }
    return tax;
  }

  static const Map<String, List<Bracket>> _brackets = {
    // ── No income tax ─────────────────────────────────────────────────────
    'AK': [(double.infinity, 0.0)],
    'FL': [(double.infinity, 0.0)],
    'NV': [(double.infinity, 0.0)],
    'NH': [(double.infinity, 0.0)], // no wages tax
    'SD': [(double.infinity, 0.0)],
    'TN': [(double.infinity, 0.0)],
    'TX': [(double.infinity, 0.0)],
    'WA': [(double.infinity, 0.0)],
    'WY': [(double.infinity, 0.0)],

    // ── Flat rate states ──────────────────────────────────────────────────
    'CO': [(double.infinity, 0.044)], // 4.4%
    'IL': [(double.infinity, 0.0495)], // 4.95%
    'IN': [(double.infinity, 0.0305)], // 3.05% (2025)
    'KY': [(double.infinity, 0.040)], // 4.0%
    'MA': [(double.infinity, 0.050)], // 5.0%
    'MI': [(double.infinity, 0.0425)], // 4.25%
    'NC': [(double.infinity, 0.045)], // 4.5%
    'PA': [(double.infinity, 0.0307)], // 3.07%
    'UT': [(double.infinity, 0.0465)], // 4.65%

    // ── Progressive states ────────────────────────────────────────────────
    // Alabama
    'AL': [(500, 0.02), (3000, 0.04), (double.infinity, 0.05)],
    // Arizona
    'AZ': [(double.infinity, 0.025)], // flat 2.5% (2023+)
    // Arkansas
    'AR': [(4999, 0.02), (9999, 0.04), (double.infinity, 0.044)],
    // California — progressive, top 13.3%
    'CA': [
      (10412, 0.01),
      (24684, 0.02),
      (38959, 0.04),
      (54081, 0.06),
      (68350, 0.08),
      (349137, 0.093),
      (418961, 0.103),
      (698274, 0.113),
      (1000000, 0.123),
      (double.infinity, 0.133),
    ],
    // Connecticut
    'CT': [
      (10000, 0.03),
      (50000, 0.05),
      (100000, 0.055),
      (200000, 0.06),
      (250000, 0.065),
      (500000, 0.069),
      (double.infinity, 0.0699),
    ],
    // Delaware
    'DE': [
      (2000, 0.0),
      (5000, 0.022),
      (10000, 0.039),
      (20000, 0.048),
      (25000, 0.052),
      (60000, 0.055),
      (double.infinity, 0.066),
    ],
    // Georgia
    'GA': [(double.infinity, 0.0549)], // flat 5.49% (2024+)
    // Hawaii
    'HI': [
      (2400, 0.014),
      (4800, 0.032),
      (9600, 0.055),
      (14400, 0.064),
      (19200, 0.068),
      (24000, 0.072),
      (36000, 0.076),
      (48000, 0.079),
      (150000, 0.0825),
      (175000, 0.09),
      (200000, 0.10),
      (double.infinity, 0.11),
    ],
    // Idaho
    'ID': [(double.infinity, 0.058)], // flat 5.8% (2024)
    // Iowa
    'IA': [
      (6000, 0.044),
      (30000, 0.0482),
      (75000, 0.057),
      (double.infinity, 0.060),
    ],
    // Kansas
    'KS': [
      (15000, 0.031),
      (30000, 0.0525),
      (double.infinity, 0.057),
    ],
    // Louisiana
    'LA': [
      (12500, 0.0185),
      (50000, 0.035),
      (double.infinity, 0.0425),
    ],
    // Maine
    'ME': [
      (24500, 0.058),
      (58050, 0.0675),
      (double.infinity, 0.0715),
    ],
    // Maryland
    'MD': [
      (1000, 0.02),
      (2000, 0.03),
      (3000, 0.04),
      (100000, 0.0475),
      (125000, 0.05),
      (150000, 0.0525),
      (250000, 0.055),
      (double.infinity, 0.0575),
    ],
    // Minnesota
    'MN': [
      (30070, 0.0535),
      (98760, 0.068),
      (183340, 0.0785),
      (double.infinity, 0.0985),
    ],
    // Mississippi
    'MS': [
      (10000, 0.0),
      (double.infinity, 0.05),
    ],
    // Missouri
    'MO': [
      (1121, 0.015),
      (2242, 0.02),
      (3363, 0.025),
      (4484, 0.03),
      (5605, 0.035),
      (6726, 0.04),
      (7847, 0.045),
      (double.infinity, 0.0495),
    ],
    // Montana
    'MT': [
      (3600, 0.01),
      (6300, 0.02),
      (9700, 0.03),
      (13000, 0.04),
      (16800, 0.05),
      (21600, 0.06),
      (double.infinity, 0.0675),
    ],
    // Nebraska
    'NE': [
      (3700, 0.0246),
      (22170, 0.0351),
      (35730, 0.0501),
      (double.infinity, 0.0664),
    ],
    // New Jersey
    'NJ': [
      (20000, 0.014),
      (35000, 0.0175),
      (40000, 0.035),
      (75000, 0.0553),
      (500000, 0.0637),
      (1000000, 0.0897),
      (double.infinity, 0.1075),
    ],
    // New Mexico
    'NM': [
      (5500, 0.017),
      (11000, 0.032),
      (16000, 0.047),
      (210000, 0.049),
      (double.infinity, 0.059),
    ],
    // New York — state only (NYC adds ~3.876%)
    'NY': [
      (17150, 0.04),
      (23600, 0.045),
      (27900, 0.0525),
      (161550, 0.0585),
      (323200, 0.0625),
      (2155350, 0.0685),
      (5000000, 0.0965),
      (25000000, 0.103),
      (double.infinity, 0.109),
    ],
    // North Dakota
    'ND': [
      (44725, 0.0195),
      (225975, 0.025),
      (double.infinity, 0.029),
    ],
    // Ohio
    'OH': [
      (26050, 0.0),
      (100000, 0.0277),
      (double.infinity, 0.0399),
    ],
    // Oklahoma
    'OK': [
      (1000, 0.0025),
      (2500, 0.0075),
      (3750, 0.0175),
      (4900, 0.0275),
      (7200, 0.0375),
      (double.infinity, 0.0475),
    ],
    // Oregon
    'OR': [
      (18400, 0.0475),
      (46200, 0.0675),
      (250000, 0.0875),
      (double.infinity, 0.099),
    ],
    // Rhode Island
    'RI': [
      (77450, 0.0375),
      (176050, 0.0475),
      (double.infinity, 0.0599),
    ],
    // South Carolina
    'SC': [
      (3200, 0.0),
      (16040, 0.03),
      (double.infinity, 0.064),
    ],
    // Vermont
    'VT': [
      (45400, 0.0335),
      (110050, 0.066),
      (229550, 0.076),
      (double.infinity, 0.0875),
    ],
    // Virginia
    'VA': [
      (3000, 0.02),
      (5000, 0.03),
      (17000, 0.05),
      (double.infinity, 0.0575),
    ],
    // West Virginia
    'WV': [
      (10000, 0.0236),
      (25000, 0.0315),
      (40000, 0.063),
      (60000, 0.065),
      (double.infinity, 0.065),
    ],
    // Wisconsin
    'WI': [
      (14320, 0.035),
      (28640, 0.044),
      (315310, 0.053),
      (double.infinity, 0.0765),
    ],
    // Washington DC
    'DC': [
      (10000, 0.04),
      (40000, 0.06),
      (60000, 0.065),
      (250000, 0.085),
      (500000, 0.0925),
      (1000000, 0.0975),
      (double.infinity, 0.1075),
    ],
  };

  /// All state codes in alphabetical order for UI dropdowns.
  static const List<String> allStateCodes = [
    'AL',
    'AK',
    'AZ',
    'AR',
    'CA',
    'CO',
    'CT',
    'DE',
    'FL',
    'GA',
    'HI',
    'ID',
    'IL',
    'IN',
    'IA',
    'KS',
    'KY',
    'LA',
    'ME',
    'MD',
    'MA',
    'MI',
    'MN',
    'MS',
    'MO',
    'MT',
    'NE',
    'NV',
    'NH',
    'NJ',
    'NM',
    'NY',
    'NC',
    'ND',
    'OH',
    'OK',
    'OR',
    'PA',
    'RI',
    'SC',
    'SD',
    'TN',
    'TX',
    'UT',
    'VT',
    'VA',
    'WA',
    'WV',
    'WI',
    'WY',
    'DC',
  ];

  static const Map<String, String> stateNames = {
    'AL': 'Alabama',
    'AK': 'Alaska',
    'AZ': 'Arizona',
    'AR': 'Arkansas',
    'CA': 'California',
    'CO': 'Colorado',
    'CT': 'Connecticut',
    'DE': 'Delaware',
    'FL': 'Florida',
    'GA': 'Georgia',
    'HI': 'Hawaii',
    'ID': 'Idaho',
    'IL': 'Illinois',
    'IN': 'Indiana',
    'IA': 'Iowa',
    'KS': 'Kansas',
    'KY': 'Kentucky',
    'LA': 'Louisiana',
    'ME': 'Maine',
    'MD': 'Maryland',
    'MA': 'Massachusetts',
    'MI': 'Michigan',
    'MN': 'Minnesota',
    'MS': 'Mississippi',
    'MO': 'Missouri',
    'MT': 'Montana',
    'NE': 'Nebraska',
    'NV': 'Nevada',
    'NH': 'New Hampshire',
    'NJ': 'New Jersey',
    'NM': 'New Mexico',
    'NY': 'New York',
    'NC': 'North Carolina',
    'ND': 'North Dakota',
    'OH': 'Ohio',
    'OK': 'Oklahoma',
    'OR': 'Oregon',
    'PA': 'Pennsylvania',
    'RI': 'Rhode Island',
    'SC': 'South Carolina',
    'SD': 'South Dakota',
    'TN': 'Tennessee',
    'TX': 'Texas',
    'UT': 'Utah',
    'VT': 'Vermont',
    'VA': 'Virginia',
    'WA': 'Washington',
    'WV': 'West Virginia',
    'WI': 'Wisconsin',
    'WY': 'Wyoming',
    'DC': 'Washington DC',
  };
}
