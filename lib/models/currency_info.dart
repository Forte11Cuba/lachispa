class CurrencyInfo {
  final String code;
  final String name;
  final String flag;
  final String symbol;
  final String country;

  const CurrencyInfo({
    required this.code,
    required this.name,
    required this.flag,
    required this.symbol,
    required this.country,
  });

  /// Get currency information by code
  static CurrencyInfo? getInfo(String code) {
    return _currencyMap[code.toUpperCase()];
  }

  /// Get all supported currencies
  static Map<String, CurrencyInfo> get allCurrencies => Map.from(_currencyMap);

  /// Check if currency code is supported
  static bool isSupported(String code) {
    return _currencyMap.containsKey(code.toUpperCase());
  }

  /// Currency database with flags, names, symbols and countries
  static const Map<String, CurrencyInfo> _currencyMap = {
    'USD': CurrencyInfo(code: 'USD', name: 'US Dollar', flag: '🇺🇸', symbol: '\$', country: 'United States'),
    'EUR': CurrencyInfo(code: 'EUR', name: 'Euro', flag: '🇪🇺', symbol: '€', country: 'European Union'),
    'GBP': CurrencyInfo(code: 'GBP', name: 'British Pound', flag: '🇬🇧', symbol: '£', country: 'United Kingdom'),
    'CUP': CurrencyInfo(code: 'CUP', name: 'Cuban Peso', flag: '🇨🇺', symbol: 'CUP', country: 'Cuba'),
    'CAD': CurrencyInfo(code: 'CAD', name: 'Canadian Dollar', flag: '🇨🇦', symbol: 'C\$', country: 'Canada'),
    'JPY': CurrencyInfo(code: 'JPY', name: 'Japanese Yen', flag: '🇯🇵', symbol: '¥', country: 'Japan'),
    'AUD': CurrencyInfo(code: 'AUD', name: 'Australian Dollar', flag: '🇦🇺', symbol: 'A\$', country: 'Australia'),
    'CHF': CurrencyInfo(code: 'CHF', name: 'Swiss Franc', flag: '🇨🇭', symbol: 'CHF', country: 'Switzerland'),
    'CNY': CurrencyInfo(code: 'CNY', name: 'Chinese Yuan', flag: '🇨🇳', symbol: '¥', country: 'China'),
    'MXN': CurrencyInfo(code: 'MXN', name: 'Mexican Peso', flag: '🇲🇽', symbol: '\$', country: 'Mexico'),
    'BRL': CurrencyInfo(code: 'BRL', name: 'Brazilian Real', flag: '🇧🇷', symbol: 'R\$', country: 'Brazil'),
    'ARS': CurrencyInfo(code: 'ARS', name: 'Argentine Peso', flag: '🇦🇷', symbol: '\$', country: 'Argentina'),
    'CLP': CurrencyInfo(code: 'CLP', name: 'Chilean Peso', flag: '🇨🇱', symbol: '\$', country: 'Chile'),
    'COP': CurrencyInfo(code: 'COP', name: 'Colombian Peso', flag: '🇨🇴', symbol: '\$', country: 'Colombia'),
    'PEN': CurrencyInfo(code: 'PEN', name: 'Peruvian Sol', flag: '🇵🇪', symbol: 'S/', country: 'Peru'),
    'UYU': CurrencyInfo(code: 'UYU', name: 'Uruguayan Peso', flag: '🇺🇾', symbol: '\$U', country: 'Uruguay'),
    'VES': CurrencyInfo(code: 'VES', name: 'Venezuelan Bolívar', flag: '🇻🇪', symbol: 'Bs.', country: 'Venezuela'),
    'INR': CurrencyInfo(code: 'INR', name: 'Indian Rupee', flag: '🇮🇳', symbol: '₹', country: 'India'),
    'KRW': CurrencyInfo(code: 'KRW', name: 'South Korean Won', flag: '🇰🇷', symbol: '₩', country: 'South Korea'),
    'SGD': CurrencyInfo(code: 'SGD', name: 'Singapore Dollar', flag: '🇸🇬', symbol: 'S\$', country: 'Singapore'),
    'HKD': CurrencyInfo(code: 'HKD', name: 'Hong Kong Dollar', flag: '🇭🇰', symbol: 'HK\$', country: 'Hong Kong'),
    'NZD': CurrencyInfo(code: 'NZD', name: 'New Zealand Dollar', flag: '🇳🇿', symbol: 'NZ\$', country: 'New Zealand'),
    'SEK': CurrencyInfo(code: 'SEK', name: 'Swedish Krona', flag: '🇸🇪', symbol: 'kr', country: 'Sweden'),
    'NOK': CurrencyInfo(code: 'NOK', name: 'Norwegian Krone', flag: '🇳🇴', symbol: 'kr', country: 'Norway'),
    'DKK': CurrencyInfo(code: 'DKK', name: 'Danish Krone', flag: '🇩🇰', symbol: 'kr', country: 'Denmark'),
    'PLN': CurrencyInfo(code: 'PLN', name: 'Polish Złoty', flag: '🇵🇱', symbol: 'zł', country: 'Poland'),
    'CZK': CurrencyInfo(code: 'CZK', name: 'Czech Koruna', flag: '🇨🇿', symbol: 'Kč', country: 'Czech Republic'),
    'HUF': CurrencyInfo(code: 'HUF', name: 'Hungarian Forint', flag: '🇭🇺', symbol: 'Ft', country: 'Hungary'),
    'RUB': CurrencyInfo(code: 'RUB', name: 'Russian Ruble', flag: '🇷🇺', symbol: '₽', country: 'Russia'),
    'TRY': CurrencyInfo(code: 'TRY', name: 'Turkish Lira', flag: '🇹🇷', symbol: '₺', country: 'Turkey'),
    'ZAR': CurrencyInfo(code: 'ZAR', name: 'South African Rand', flag: '🇿🇦', symbol: 'R', country: 'South Africa'),
    'EGP': CurrencyInfo(code: 'EGP', name: 'Egyptian Pound', flag: '🇪🇬', symbol: '£', country: 'Egypt'),
    'NGN': CurrencyInfo(code: 'NGN', name: 'Nigerian Naira', flag: '🇳🇬', symbol: '₦', country: 'Nigeria'),
    'GHS': CurrencyInfo(code: 'GHS', name: 'Ghanaian Cedi', flag: '🇬🇭', symbol: '₵', country: 'Ghana'),
    'KES': CurrencyInfo(code: 'KES', name: 'Kenyan Shilling', flag: '🇰🇪', symbol: 'KSh', country: 'Kenya'),
    'MAD': CurrencyInfo(code: 'MAD', name: 'Moroccan Dirham', flag: '🇲🇦', symbol: 'DH', country: 'Morocco'),
    
    // Middle East & Central Asia
    'AED': CurrencyInfo(code: 'AED', name: 'UAE Dirham', flag: '🇦🇪', symbol: 'د.إ', country: 'United Arab Emirates'),
    'SAR': CurrencyInfo(code: 'SAR', name: 'Saudi Riyal', flag: '🇸🇦', symbol: '﷼', country: 'Saudi Arabia'),
    'QAR': CurrencyInfo(code: 'QAR', name: 'Qatari Riyal', flag: '🇶🇦', symbol: '﷼', country: 'Qatar'),
    'KWD': CurrencyInfo(code: 'KWD', name: 'Kuwaiti Dinar', flag: '🇰🇼', symbol: 'د.ك', country: 'Kuwait'),
    'BHD': CurrencyInfo(code: 'BHD', name: 'Bahraini Dinar', flag: '🇧🇭', symbol: '.د.ب', country: 'Bahrain'),
    'OMR': CurrencyInfo(code: 'OMR', name: 'Omani Rial', flag: '🇴🇲', symbol: '﷼', country: 'Oman'),
    'JOD': CurrencyInfo(code: 'JOD', name: 'Jordanian Dinar', flag: '🇯🇴', symbol: 'د.ا', country: 'Jordan'),
    'LBP': CurrencyInfo(code: 'LBP', name: 'Lebanese Pound', flag: '🇱🇧', symbol: 'ل.ل', country: 'Lebanon'),
    'ILS': CurrencyInfo(code: 'ILS', name: 'Israeli Shekel', flag: '🇮🇱', symbol: '₪', country: 'Israel'),
    'IRR': CurrencyInfo(code: 'IRR', name: 'Iranian Rial', flag: '🇮🇷', symbol: '﷼', country: 'Iran'),
    'IRT': CurrencyInfo(code: 'IRT', name: 'Iranian Toman', flag: '🇮🇷', symbol: 'تومان', country: 'Iran'),
    'IQD': CurrencyInfo(code: 'IQD', name: 'Iraqi Dinar', flag: '🇮🇶', symbol: 'ع.د', country: 'Iraq'),
    'AFN': CurrencyInfo(code: 'AFN', name: 'Afghan Afghani', flag: '🇦🇫', symbol: '؋', country: 'Afghanistan'),
    'PKR': CurrencyInfo(code: 'PKR', name: 'Pakistani Rupee', flag: '🇵🇰', symbol: '₨', country: 'Pakistan'),
    'BDT': CurrencyInfo(code: 'BDT', name: 'Bangladeshi Taka', flag: '🇧🇩', symbol: '৳', country: 'Bangladesh'),
    'LKR': CurrencyInfo(code: 'LKR', name: 'Sri Lankan Rupee', flag: '🇱🇰', symbol: '₨', country: 'Sri Lanka'),
    'NPR': CurrencyInfo(code: 'NPR', name: 'Nepalese Rupee', flag: '🇳🇵', symbol: '₨', country: 'Nepal'),
    'BTN': CurrencyInfo(code: 'BTN', name: 'Bhutanese Ngultrum', flag: '🇧🇹', symbol: 'Nu.', country: 'Bhutan'),
    'MVR': CurrencyInfo(code: 'MVR', name: 'Maldivian Rufiyaa', flag: '🇲🇻', symbol: '.ރ', country: 'Maldives'),
    'AMD': CurrencyInfo(code: 'AMD', name: 'Armenian Dram', flag: '🇦🇲', symbol: '֏', country: 'Armenia'),
    'AZN': CurrencyInfo(code: 'AZN', name: 'Azerbaijani Manat', flag: '🇦🇿', symbol: '₼', country: 'Azerbaijan'),
    'GEL': CurrencyInfo(code: 'GEL', name: 'Georgian Lari', flag: '🇬🇪', symbol: '₾', country: 'Georgia'),
    'KZT': CurrencyInfo(code: 'KZT', name: 'Kazakhstani Tenge', flag: '🇰🇿', symbol: '₸', country: 'Kazakhstan'),
    'KGS': CurrencyInfo(code: 'KGS', name: 'Kyrgyz Som', flag: '🇰🇬', symbol: 'лв', country: 'Kyrgyzstan'),
    'TJS': CurrencyInfo(code: 'TJS', name: 'Tajik Somoni', flag: '🇹🇯', symbol: 'ЅМ', country: 'Tajikistan'),
    'TMT': CurrencyInfo(code: 'TMT', name: 'Turkmen Manat', flag: '🇹🇲', symbol: 'T', country: 'Turkmenistan'),
    'UZS': CurrencyInfo(code: 'UZS', name: 'Uzbek Som', flag: '🇺🇿', symbol: 'лв', country: 'Uzbekistan'),
    
    // Southeast Asia & Pacific
    'THB': CurrencyInfo(code: 'THB', name: 'Thai Baht', flag: '🇹🇭', symbol: '฿', country: 'Thailand'),
    'VND': CurrencyInfo(code: 'VND', name: 'Vietnamese Dong', flag: '🇻🇳', symbol: '₫', country: 'Vietnam'),
    'IDR': CurrencyInfo(code: 'IDR', name: 'Indonesian Rupiah', flag: '🇮🇩', symbol: 'Rp', country: 'Indonesia'),
    'MYR': CurrencyInfo(code: 'MYR', name: 'Malaysian Ringgit', flag: '🇲🇾', symbol: 'RM', country: 'Malaysia'),
    'PHP': CurrencyInfo(code: 'PHP', name: 'Philippine Peso', flag: '🇵🇭', symbol: '₱', country: 'Philippines'),
    'BND': CurrencyInfo(code: 'BND', name: 'Brunei Dollar', flag: '🇧🇳', symbol: 'B\$', country: 'Brunei'),
    'KHR': CurrencyInfo(code: 'KHR', name: 'Cambodian Riel', flag: '🇰🇭', symbol: '៛', country: 'Cambodia'),
    'LAK': CurrencyInfo(code: 'LAK', name: 'Lao Kip', flag: '🇱🇦', symbol: '₭', country: 'Laos'),
    'MMK': CurrencyInfo(code: 'MMK', name: 'Myanmar Kyat', flag: '🇲🇲', symbol: 'K', country: 'Myanmar'),
    'PGK': CurrencyInfo(code: 'PGK', name: 'Papua New Guinea Kina', flag: '🇵🇬', symbol: 'K', country: 'Papua New Guinea'),
    'FJD': CurrencyInfo(code: 'FJD', name: 'Fijian Dollar', flag: '🇫🇯', symbol: 'FJ\$', country: 'Fiji'),
    'VUV': CurrencyInfo(code: 'VUV', name: 'Vanuatu Vatu', flag: '🇻🇺', symbol: 'VT', country: 'Vanuatu'),
    'WST': CurrencyInfo(code: 'WST', name: 'Samoan Tala', flag: '🇼🇸', symbol: 'T', country: 'Samoa'),
    'TOP': CurrencyInfo(code: 'TOP', name: 'Tongan Paʻanga', flag: '🇹🇴', symbol: 'T\$', country: 'Tonga'),
    'TWD': CurrencyInfo(code: 'TWD', name: 'Taiwan Dollar', flag: '🇹🇼', symbol: 'NT\$', country: 'Taiwan'),
    
    // Europe (additional)
    'ISK': CurrencyInfo(code: 'ISK', name: 'Icelandic Króna', flag: '🇮🇸', symbol: 'kr', country: 'Iceland'),
    'BGN': CurrencyInfo(code: 'BGN', name: 'Bulgarian Lev', flag: '🇧🇬', symbol: 'лв', country: 'Bulgaria'),
    'RON': CurrencyInfo(code: 'RON', name: 'Romanian Leu', flag: '🇷🇴', symbol: 'lei', country: 'Romania'),
    'HRK': CurrencyInfo(code: 'HRK', name: 'Croatian Kuna', flag: '🇭🇷', symbol: 'kn', country: 'Croatia'),
    'RSD': CurrencyInfo(code: 'RSD', name: 'Serbian Dinar', flag: '🇷🇸', symbol: 'Дин.', country: 'Serbia'),
    'BAM': CurrencyInfo(code: 'BAM', name: 'Bosnia-Herzegovina Mark', flag: '🇧🇦', symbol: 'KM', country: 'Bosnia and Herzegovina'),
    'MKD': CurrencyInfo(code: 'MKD', name: 'Macedonian Denar', flag: '🇲🇰', symbol: 'ден', country: 'North Macedonia'),
    'ALL': CurrencyInfo(code: 'ALL', name: 'Albanian Lek', flag: '🇦🇱', symbol: 'Lek', country: 'Albania'),
    
    // Africa (additional)
    'ETB': CurrencyInfo(code: 'ETB', name: 'Ethiopian Birr', flag: '🇪🇹', symbol: 'Br', country: 'Ethiopia'),
    'UGX': CurrencyInfo(code: 'UGX', name: 'Ugandan Shilling', flag: '🇺🇬', symbol: 'USh', country: 'Uganda'),
    'TZS': CurrencyInfo(code: 'TZS', name: 'Tanzanian Shilling', flag: '🇹🇿', symbol: 'TSh', country: 'Tanzania'),
    'RWF': CurrencyInfo(code: 'RWF', name: 'Rwandan Franc', flag: '🇷🇼', symbol: 'R₣', country: 'Rwanda'),
    'BIF': CurrencyInfo(code: 'BIF', name: 'Burundian Franc', flag: '🇧🇮', symbol: '₣', country: 'Burundi'),
    'DJF': CurrencyInfo(code: 'DJF', name: 'Djiboutian Franc', flag: '🇩🇯', symbol: '₣', country: 'Djibouti'),
    'ERN': CurrencyInfo(code: 'ERN', name: 'Eritrean Nakfa', flag: '🇪🇷', symbol: 'Nfk', country: 'Eritrea'),
    'SOS': CurrencyInfo(code: 'SOS', name: 'Somali Shilling', flag: '🇸🇴', symbol: 'S', country: 'Somalia'),
    'SCR': CurrencyInfo(code: 'SCR', name: 'Seychellois Rupee', flag: '🇸🇨', symbol: '₨', country: 'Seychelles'),
    'MUR': CurrencyInfo(code: 'MUR', name: 'Mauritian Rupee', flag: '🇲🇺', symbol: '₨', country: 'Mauritius'),
    'MGA': CurrencyInfo(code: 'MGA', name: 'Malagasy Ariary', flag: '🇲🇬', symbol: 'Ar', country: 'Madagascar'),
    'KMF': CurrencyInfo(code: 'KMF', name: 'Comorian Franc', flag: '🇰🇲', symbol: '₣', country: 'Comoros'),
    'MWK': CurrencyInfo(code: 'MWK', name: 'Malawian Kwacha', flag: '🇲🇼', symbol: 'MK', country: 'Malawi'),
    'ZMW': CurrencyInfo(code: 'ZMW', name: 'Zambian Kwacha', flag: '🇿🇲', symbol: 'ZK', country: 'Zambia'),
    'ZWL': CurrencyInfo(code: 'ZWL', name: 'Zimbabwean Dollar', flag: '🇿🇼', symbol: 'Z\$', country: 'Zimbabwe'),
    'BWP': CurrencyInfo(code: 'BWP', name: 'Botswanan Pula', flag: '🇧🇼', symbol: 'P', country: 'Botswana'),
    'LSL': CurrencyInfo(code: 'LSL', name: 'Lesotho Loti', flag: '🇱🇸', symbol: 'L', country: 'Lesotho'),
    'SZL': CurrencyInfo(code: 'SZL', name: 'Swazi Lilangeni', flag: '🇸🇿', symbol: 'E', country: 'Eswatini'),
    'NAD': CurrencyInfo(code: 'NAD', name: 'Namibian Dollar', flag: '🇳🇦', symbol: 'N\$', country: 'Namibia'),
    'AOA': CurrencyInfo(code: 'AOA', name: 'Angolan Kwanza', flag: '🇦🇴', symbol: 'Kz', country: 'Angola'),
    'CDF': CurrencyInfo(code: 'CDF', name: 'Congolese Franc', flag: '🇨🇩', symbol: '₣', country: 'Democratic Republic of the Congo'),
    'XAF': CurrencyInfo(code: 'XAF', name: 'Central African Franc', flag: '🇨🇫', symbol: '₣', country: 'Central Africa'),
    'XOF': CurrencyInfo(code: 'XOF', name: 'West African Franc', flag: '🇸🇳', symbol: '₣', country: 'West Africa'),
    'GMD': CurrencyInfo(code: 'GMD', name: 'Gambian Dalasi', flag: '🇬🇲', symbol: 'D', country: 'Gambia'),
    'GNF': CurrencyInfo(code: 'GNF', name: 'Guinean Franc', flag: '🇬🇳', symbol: '₣', country: 'Guinea'),
    'SLL': CurrencyInfo(code: 'SLL', name: 'Sierra Leonean Leone', flag: '🇸🇱', symbol: 'Le', country: 'Sierra Leone'),
    'LRD': CurrencyInfo(code: 'LRD', name: 'Liberian Dollar', flag: '🇱🇷', symbol: 'L\$', country: 'Liberia'),
    'CVE': CurrencyInfo(code: 'CVE', name: 'Cape Verdean Escudo', flag: '🇨🇻', symbol: 'Esc', country: 'Cape Verde'),
    'STD': CurrencyInfo(code: 'STD', name: 'São Tomé and Príncipe Dobra', flag: '🇸🇹', symbol: 'Db', country: 'São Tomé and Príncipe'),
    'MRO': CurrencyInfo(code: 'MRO', name: 'Mauritanian Ouguiya', flag: '🇲🇷', symbol: 'UM', country: 'Mauritania'),
    'TND': CurrencyInfo(code: 'TND', name: 'Tunisian Dinar', flag: '🇹🇳', symbol: 'د.ت', country: 'Tunisia'),
    'LYD': CurrencyInfo(code: 'LYD', name: 'Libyan Dinar', flag: '🇱🇾', symbol: 'ل.د', country: 'Libya'),
    'DZD': CurrencyInfo(code: 'DZD', name: 'Algerian Dinar', flag: '🇩🇿', symbol: 'د.ج', country: 'Algeria'),
    'SDG': CurrencyInfo(code: 'SDG', name: 'Sudanese Pound', flag: '🇸🇩', symbol: 'ج.س.', country: 'Sudan'),
    'SSP': CurrencyInfo(code: 'SSP', name: 'South Sudanese Pound', flag: '🇸🇸', symbol: '£', country: 'South Sudan'),
    
    // Caribbean & Central America (additional)
    'JMD': CurrencyInfo(code: 'JMD', name: 'Jamaican Dollar', flag: '🇯🇲', symbol: 'J\$', country: 'Jamaica'),
    'HTG': CurrencyInfo(code: 'HTG', name: 'Haitian Gourde', flag: '🇭🇹', symbol: 'G', country: 'Haiti'),
    'DOP': CurrencyInfo(code: 'DOP', name: 'Dominican Peso', flag: '🇩🇴', symbol: 'RD\$', country: 'Dominican Republic'),
    'CRC': CurrencyInfo(code: 'CRC', name: 'Costa Rican Colón', flag: '🇨🇷', symbol: '₡', country: 'Costa Rica'),
    'GTQ': CurrencyInfo(code: 'GTQ', name: 'Guatemalan Quetzal', flag: '🇬🇹', symbol: 'Q', country: 'Guatemala'),
    'HNL': CurrencyInfo(code: 'HNL', name: 'Honduran Lempira', flag: '🇭🇳', symbol: 'L', country: 'Honduras'),
    'NIO': CurrencyInfo(code: 'NIO', name: 'Nicaraguan Córdoba', flag: '🇳🇮', symbol: 'C\$', country: 'Nicaragua'),
    'PAB': CurrencyInfo(code: 'PAB', name: 'Panamanian Balboa', flag: '🇵🇦', symbol: 'B/.', country: 'Panama'),
    'BZD': CurrencyInfo(code: 'BZD', name: 'Belize Dollar', flag: '🇧🇿', symbol: 'BZ\$', country: 'Belize'),
    'SVC': CurrencyInfo(code: 'SVC', name: 'Salvadoran Colón', flag: '🇸🇻', symbol: '₡', country: 'El Salvador'),
    'BBD': CurrencyInfo(code: 'BBD', name: 'Barbadian Dollar', flag: '🇧🇧', symbol: 'Bds\$', country: 'Barbados'),
    'TTD': CurrencyInfo(code: 'TTD', name: 'Trinidad & Tobago Dollar', flag: '🇹🇹', symbol: 'TT\$', country: 'Trinidad and Tobago'),
    'GYD': CurrencyInfo(code: 'GYD', name: 'Guyanese Dollar', flag: '🇬🇾', symbol: 'G\$', country: 'Guyana'),
    'SRD': CurrencyInfo(code: 'SRD', name: 'Surinamese Dollar', flag: '🇸🇷', symbol: 'Sr\$', country: 'Suriname'),
    'AWG': CurrencyInfo(code: 'AWG', name: 'Aruban Florin', flag: '🇦🇼', symbol: 'ƒ', country: 'Aruba'),
    'ANG': CurrencyInfo(code: 'ANG', name: 'Netherlands Antillean Guilder', flag: '🇳🇱', symbol: 'ƒ', country: 'Netherlands Antilles'),
    'XCD': CurrencyInfo(code: 'XCD', name: 'East Caribbean Dollar', flag: '🇩🇲', symbol: 'EC\$', country: 'Eastern Caribbean'),
    'KYD': CurrencyInfo(code: 'KYD', name: 'Cayman Islands Dollar', flag: '🇰🇾', symbol: 'CI\$', country: 'Cayman Islands'),
    'BMD': CurrencyInfo(code: 'BMD', name: 'Bermudian Dollar', flag: '🇧🇲', symbol: 'BD\$', country: 'Bermuda'),
    'BSD': CurrencyInfo(code: 'BSD', name: 'Bahamian Dollar', flag: '🇧🇸', symbol: 'B\$', country: 'Bahamas'),
    'VEF': CurrencyInfo(code: 'VEF', name: 'Venezuelan Bolívar Fuerte', flag: '🇻🇪', symbol: 'Bs.F.', country: 'Venezuela'),
    
    // Alternative currency territories
    'FKP': CurrencyInfo(code: 'FKP', name: 'Falkland Islands Pound', flag: '🇫🇰', symbol: '£', country: 'Falkland Islands'),
    'GIP': CurrencyInfo(code: 'GIP', name: 'Gibraltar Pound', flag: '🇬🇮', symbol: '£', country: 'Gibraltar'),
    'SHP': CurrencyInfo(code: 'SHP', name: 'Saint Helena Pound', flag: '🇸🇭', symbol: '£', country: 'Saint Helena'),
    'GGP': CurrencyInfo(code: 'GGP', name: 'Guernsey Pound', flag: '🇬🇬', symbol: '£', country: 'Guernsey'),
    'JEP': CurrencyInfo(code: 'JEP', name: 'Jersey Pound', flag: '🇯🇪', symbol: '£', country: 'Jersey'),
    'IMP': CurrencyInfo(code: 'IMP', name: 'Isle of Man Pound', flag: '🇮🇲', symbol: '£', country: 'Isle of Man'),
    'CNH': CurrencyInfo(code: 'CNH', name: 'Chinese Yuan (Offshore)', flag: '🇨🇳', symbol: '¥', country: 'China (Offshore)'),
    'CLF': CurrencyInfo(code: 'CLF', name: 'Chilean Unit of Account', flag: '🇨🇱', symbol: 'UF', country: 'Chile'),
    'XPF': CurrencyInfo(code: 'XPF', name: 'CFP Franc', flag: '🇵🇫', symbol: '₣', country: 'French Pacific Territories'),
    'MOP': CurrencyInfo(code: 'MOP', name: 'Macanese Pataca', flag: '🇲🇴', symbol: 'MOP\$', country: 'Macau'),
    
    // Additional European & other currencies
    'BYN': CurrencyInfo(code: 'BYN', name: 'Belarusian Ruble', flag: '🇧🇾', symbol: 'Br', country: 'Belarus'),
    'BYR': CurrencyInfo(code: 'BYR', name: 'Belarusian Ruble (Old)', flag: '🇧🇾', symbol: 'p.', country: 'Belarus'),
    'UAH': CurrencyInfo(code: 'UAH', name: 'Ukrainian Hryvnia', flag: '🇺🇦', symbol: '₴', country: 'Ukraine'),
    'MDL': CurrencyInfo(code: 'MDL', name: 'Moldovan Leu', flag: '🇲🇩', symbol: 'L', country: 'Moldova'),
    'MNT': CurrencyInfo(code: 'MNT', name: 'Mongolian Tugrik', flag: '🇲🇳', symbol: '₮', country: 'Mongolia'),
    'PYG': CurrencyInfo(code: 'PYG', name: 'Paraguayan Guarani', flag: '🇵🇾', symbol: 'Gs', country: 'Paraguay'),
    'BOB': CurrencyInfo(code: 'BOB', name: 'Bolivian Boliviano', flag: '🇧🇴', symbol: 'Bs', country: 'Bolivia'),
    
    // Precious metals & cryptocurrencies
    'XAU': CurrencyInfo(code: 'XAU', name: 'Gold Ounce', flag: '🥇', symbol: 'oz', country: 'Precious Metal'),
    'XAG': CurrencyInfo(code: 'XAG', name: 'Silver Ounce', flag: '🥈', symbol: 'oz', country: 'Precious Metal'),
    'XPD': CurrencyInfo(code: 'XPD', name: 'Palladium Ounce', flag: '⚪', symbol: 'oz', country: 'Precious Metal'),
    'XPT': CurrencyInfo(code: 'XPT', name: 'Platinum Ounce', flag: '⚫', symbol: 'oz', country: 'Precious Metal'),
    'XDR': CurrencyInfo(code: 'XDR', name: 'Special Drawing Rights', flag: '🏛️', symbol: 'SDR', country: 'International Monetary Fund'),
  };

  @override
  String toString() => '$flag $code - $name';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CurrencyInfo && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;
}