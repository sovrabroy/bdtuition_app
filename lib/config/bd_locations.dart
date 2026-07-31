/// Hardcoded Bangladesh location data used across the app.
///
/// [kBdLocations] maps every district (64 zila) to its list of areas
/// (city thanas / upazilas). Dhaka and Chittagong include their city
/// neighbourhoods; other districts list their upazilas.
///
/// Usage:
///   - City dropdown  -> kBdDistricts (the keys, in order)
///   - Area dropdown  -> kBdLocations[selectedCity]
///
/// This is data only; it does not touch any existing logic.
library;

/// Academic groups (SSC / HSC).
const List<String> kAcademicGroups = ['Science', 'Commerce', 'Arts'];

const Map<String, List<String>> kBdLocations = {
  // ===== Dhaka Division =====
  'Dhaka': [
    'Uttara', 'Mirpur', 'Pallabi', 'Kafrul', 'Cantonment', 'Mohammadpur',
    'Dhanmondi', 'Gulshan', 'Banani', 'Baridhara', 'Bashundhara', 'Badda',
    'Rampura', 'Khilgaon', 'Malibagh', 'Mugda', 'Motijheel', 'Paltan',
    'Tejgaon', 'Farmgate', 'Mohakhali', 'Shahbagh', 'New Market', 'Azimpur',
    'Lalbagh', 'Kotwali (Old Dhaka)', 'Wari', 'Sutrapur', 'Gendaria',
    'Shyampur', 'Jatrabari', 'Demra', 'Sabujbagh', 'Kamrangirchar',
    'Hazaribagh', 'Savar', 'Dhamrai', 'Keraniganj', 'Nawabganj', 'Dohar',
  ],
  'Gazipur': [
    'Gazipur Sadar', 'Tongi', 'Board Bazar', 'Chandra', 'Kaliakair',
    'Kapasia', 'Sreepur', 'Kaliganj',
  ],
  'Kishoreganj': [
    'Kishoreganj Sadar', 'Bhairab', 'Bajitpur', 'Katiadi', 'Kuliarchar',
    'Hossainpur', 'Itna', 'Karimganj', 'Mithamain', 'Nikli', 'Pakundia',
    'Tarail', 'Austagram',
  ],
  'Manikganj': [
    'Manikganj Sadar', 'Singair', 'Saturia', 'Harirampur', 'Ghior',
    'Daulatpur', 'Shibalaya',
  ],
  'Munshiganj': [
    'Munshiganj Sadar', 'Sreenagar', 'Sirajdikhan', 'Louhajang', 'Gazaria',
    'Tongibari',
  ],
  'Narayanganj': [
    'Narayanganj Sadar', 'Fatullah', 'Siddhirganj', 'Bandar', 'Rupganj',
    'Sonargaon', 'Araihazar',
  ],
  'Narsingdi': [
    'Narsingdi Sadar', 'Palash', 'Shibpur', 'Belabo', 'Monohardi', 'Raipura',
  ],
  'Tangail': [
    'Tangail Sadar', 'Mirzapur', 'Ghatail', 'Kalihati', 'Sakhipur', 'Basail',
    'Bhuapur', 'Delduar', 'Dhanbari', 'Gopalpur', 'Madhupur', 'Nagarpur',
  ],
  'Faridpur': [
    'Faridpur Sadar', 'Boalmari', 'Alfadanga', 'Bhanga', 'Charbhadrasan',
    'Madhukhali', 'Nagarkanda', 'Sadarpur', 'Saltha',
  ],
  'Gopalganj': [
    'Gopalganj Sadar', 'Tungipara', 'Kotalipara', 'Kashiani', 'Muksudpur',
  ],
  'Madaripur': [
    'Madaripur Sadar', 'Kalkini', 'Rajoir', 'Shibchar', 'Dasar',
  ],
  'Rajbari': [
    'Rajbari Sadar', 'Baliakandi', 'Goalandaghat', 'Pangsha', 'Kalukhali',
  ],
  'Shariatpur': [
    'Shariatpur Sadar', 'Naria', 'Zajira', 'Bhedarganj', 'Damudya',
    'Gosairhat',
  ],

  // ===== Chittagong Division =====
  'Chattogram': [
    'Kotwali', 'Panchlaish', 'Chandgaon', 'Bakalia', 'Khulshi', 'Nasirabad',
    'GEC', 'Muradpur', 'Chawkbazar', 'Agrabad', 'Halishahar', 'Pahartali',
    'Double Mooring', 'Patenga', 'EPZ', 'Bayezid', 'Sitakunda', 'Mirsharai',
    'Hathazari', 'Raozan', 'Rangunia', 'Fatikchhari', 'Anwara', 'Boalkhali',
    'Patiya', 'Chandanaish', 'Satkania', 'Lohagara', 'Banshkhali',
    'Sandwip', 'Karnaphuli',
  ],
  "Cox's Bazar": [
    "Cox's Bazar Sadar", 'Chakaria', 'Teknaf', 'Ukhia', 'Ramu', 'Maheshkhali',
    'Kutubdia', 'Pekua',
  ],
  'Bandarban': [
    'Bandarban Sadar', 'Thanchi', 'Lama', 'Ruma', 'Rowangchhari', 'Alikadam',
    'Naikhongchhari',
  ],
  'Khagrachhari': [
    'Khagrachhari Sadar', 'Dighinala', 'Panchhari', 'Ramgarh', 'Matiranga',
    'Manikchhari', 'Mahalchhari', 'Laxmichhari',
  ],
  'Rangamati': [
    'Rangamati Sadar', 'Kaptai', 'Kaukhali', 'Baghaichhari', 'Barkal',
    'Belaichhari', 'Juraichhari', 'Langadu', 'Naniarchar', 'Rajasthali',
  ],
  'Feni': [
    'Feni Sadar', 'Chhagalnaiya', 'Daganbhuiyan', 'Parshuram', 'Sonagazi',
    'Fulgazi',
  ],
  'Lakshmipur': [
    'Lakshmipur Sadar', 'Raipur', 'Ramganj', 'Ramgati', 'Kamalnagar',
  ],
  'Cumilla': [
    'Cumilla Sadar', 'Sadar Dakshin', 'Laksam', 'Daudkandi', 'Chandina',
    'Chauddagram', 'Barura', 'Brahmanpara', 'Burichang', 'Debidwar', 'Homna',
    'Muradnagar', 'Nangalkot', 'Titas', 'Meghna', 'Monohorgonj',
  ],
  'Noakhali': [
    'Noakhali Sadar', 'Begumganj', 'Chatkhil', 'Companiganj', 'Hatiya',
    'Senbagh', 'Sonaimuri', 'Subarnachar', 'Kabirhat',
  ],
  'Brahmanbaria': [
    'Brahmanbaria Sadar', 'Ashuganj', 'Nabinagar', 'Sarail', 'Nasirnagar',
    'Bancharampur', 'Kasba', 'Akhaura', 'Bijoynagar',
  ],
  'Chandpur': [
    'Chandpur Sadar', 'Faridganj', 'Haimchar', 'Hajiganj', 'Kachua',
    'Matlab Uttar', 'Matlab Dakshin', 'Shahrasti',
  ],

  // ===== Rajshahi Division =====
  'Rajshahi': [
    'Boalia', 'Motihar', 'Rajpara', 'Shah Makhdum', 'Paba', 'Godagari',
    'Tanore', 'Bagmara', 'Charghat', 'Durgapur', 'Mohanpur', 'Bagha',
    'Puthia',
  ],
  'Natore': [
    'Natore Sadar', 'Singra', 'Baraigram', 'Bagatipara', 'Gurudaspur',
    'Lalpur', 'Naldanga',
  ],
  'Naogaon': [
    'Naogaon Sadar', 'Atrai', 'Badalgachhi', 'Dhamoirhat', 'Manda',
    'Mahadebpur', 'Niamatpur', 'Patnitala', 'Porsha', 'Raninagar', 'Sapahar',
  ],
  'Chapainawabganj': [
    'Chapainawabganj Sadar', 'Shibganj', 'Gomastapur', 'Nachole', 'Bholahat',
  ],
  'Pabna': [
    'Pabna Sadar', 'Ishwardi', 'Bera', 'Bhangura', 'Chatmohar', 'Faridpur',
    'Atgharia', 'Santhia', 'Sujanagar',
  ],
  'Bogura': [
    'Bogura Sadar', 'Sherpur', 'Shibganj', 'Adamdighi', 'Dhunat',
    'Dhupchanchia', 'Gabtali', 'Kahaloo', 'Nandigram', 'Sariakandi',
    'Shajahanpur', 'Sonatala',
  ],
  'Sirajganj': [
    'Sirajganj Sadar', 'Belkuchi', 'Chauhali', 'Kamarkhanda', 'Kazipur',
    'Raiganj', 'Shahjadpur', 'Tarash', 'Ullapara',
  ],
  'Joypurhat': [
    'Joypurhat Sadar', 'Akkelpur', 'Kalai', 'Khetlal', 'Panchbibi',
  ],

  // ===== Khulna Division =====
  'Khulna': [
    'Khulna Sadar', 'Sonadanga', 'Khalishpur', 'Daulatpur', 'Khan Jahan Ali',
    'Batiaghata', 'Dacope', 'Dumuria', 'Dighalia', 'Koyra', 'Paikgachha',
    'Phultala', 'Rupsa', 'Terokhada',
  ],
  'Bagerhat': [
    'Bagerhat Sadar', 'Mongla', 'Morrelganj', 'Rampal', 'Fakirhat',
    'Chitalmari', 'Kachua', 'Mollahat', 'Sarankhola',
  ],
  'Satkhira': [
    'Satkhira Sadar', 'Kalaroa', 'Tala', 'Assasuni', 'Debhata', 'Kaliganj',
    'Shyamnagar',
  ],
  'Jashore': [
    'Jashore Sadar', 'Abhaynagar', 'Bagherpara', 'Chaugachha', 'Jhikargachha',
    'Keshabpur', 'Manirampur', 'Sharsha',
  ],
  'Jhenaidah': [
    'Jhenaidah Sadar', 'Kaliganj', 'Kotchandpur', 'Maheshpur', 'Harinakunda',
    'Shailkupa',
  ],
  'Magura': [
    'Magura Sadar', 'Mohammadpur', 'Shalikha', 'Sreepur',
  ],
  'Narail': [
    'Narail Sadar', 'Kalia', 'Lohagara',
  ],
  'Kushtia': [
    'Kushtia Sadar', 'Kumarkhali', 'Bheramara', 'Daulatpur', 'Khoksa',
    'Mirpur',
  ],
  'Chuadanga': [
    'Chuadanga Sadar', 'Alamdanga', 'Damurhuda', 'Jibannagar',
  ],
  'Meherpur': [
    'Meherpur Sadar', 'Gangni', 'Mujibnagar',
  ],

  // ===== Barishal Division =====
  'Barishal': [
    'Barishal Sadar', 'Bakerganj', 'Babuganj', 'Banaripara', 'Gaurnadi',
    'Hizla', 'Mehendiganj', 'Muladi', 'Wazirpur', 'Agailjhara',
  ],
  'Bhola': [
    'Bhola Sadar', 'Char Fasson', 'Lalmohan', 'Borhanuddin', 'Daulatkhan',
    'Manpura', 'Tazumuddin',
  ],
  'Patuakhali': [
    'Patuakhali Sadar', 'Bauphal', 'Dashmina', 'Dumki', 'Galachipa',
    'Kalapara', 'Mirzaganj', 'Rangabali',
  ],
  'Pirojpur': [
    'Pirojpur Sadar', 'Bhandaria', 'Kawkhali', 'Mathbaria', 'Nazirpur',
    'Nesarabad (Swarupkathi)', 'Zianagar',
  ],
  'Barguna': [
    'Barguna Sadar', 'Amtali', 'Bamna', 'Betagi', 'Patharghata', 'Taltali',
  ],
  'Jhalokati': [
    'Jhalokati Sadar', 'Kathalia', 'Nalchity', 'Rajapur',
  ],

  // ===== Sylhet Division =====
  'Sylhet': [
    'Sylhet Sadar', 'Dakshin Surma', 'Osmani Nagar', 'Beanibazar',
    'Bishwanath', 'Companiganj', 'Fenchuganj', 'Golapganj', 'Gowainghat',
    'Jaintiapur', 'Kanaighat', 'Zakiganj', 'Balaganj',
  ],
  'Moulvibazar': [
    'Moulvibazar Sadar', 'Barlekha', 'Kamalganj', 'Kulaura', 'Rajnagar',
    'Sreemangal', 'Juri',
  ],
  'Habiganj': [
    'Habiganj Sadar', 'Ajmiriganj', 'Bahubal', 'Baniyachong', 'Chunarughat',
    'Lakhai', 'Madhabpur', 'Nabiganj', 'Shayestaganj',
  ],
  'Sunamganj': [
    'Sunamganj Sadar', 'Bishwambarpur', 'Chhatak', 'Derai', 'Dharampasha',
    'Dowarabazar', 'Jagannathpur', 'Jamalganj', 'Sulla', 'Tahirpur',
    'Dakshin Sunamganj', 'Madhyanagar',
  ],

  // ===== Rangpur Division =====
  'Rangpur': [
    'Rangpur Sadar', 'Badarganj', 'Gangachhara', 'Kaunia', 'Mithapukur',
    'Pirgachha', 'Pirganj', 'Taraganj',
  ],
  'Dinajpur': [
    'Dinajpur Sadar', 'Birampur', 'Birganj', 'Biral', 'Bochaganj',
    'Chirirbandar', 'Phulbari', 'Ghoraghat', 'Hakimpur', 'Kaharole',
    'Khansama', 'Nawabganj', 'Parbatipur',
  ],
  'Kurigram': [
    'Kurigram Sadar', 'Bhurungamari', 'Char Rajibpur', 'Chilmari', 'Phulbari',
    'Nageshwari', 'Rajarhat', 'Raomari', 'Ulipur',
  ],
  'Gaibandha': [
    'Gaibandha Sadar', 'Fulchhari', 'Gobindaganj', 'Palashbari', 'Sadullapur',
    'Sughatta', 'Sundarganj',
  ],
  'Nilphamari': [
    'Nilphamari Sadar', 'Dimla', 'Domar', 'Jaldhaka', 'Kishoreganj',
    'Saidpur',
  ],
  'Panchagarh': [
    'Panchagarh Sadar', 'Atwari', 'Boda', 'Debiganj', 'Tetulia',
  ],
  'Thakurgaon': [
    'Thakurgaon Sadar', 'Baliadangi', 'Haripur', 'Pirganj', 'Ranisankail',
  ],
  'Lalmonirhat': [
    'Lalmonirhat Sadar', 'Aditmari', 'Hatibandha', 'Kaliganj', 'Patgram',
  ],

  // ===== Mymensingh Division =====
  'Mymensingh': [
    'Mymensingh Sadar', 'Bhaluka', 'Trishal', 'Muktagachha', 'Fulbaria',
    'Gaffargaon', 'Gauripur', 'Haluaghat', 'Ishwarganj', 'Nandail',
    'Phulpur', 'Dhobaura', 'Tarakanda',
  ],
  'Jamalpur': [
    'Jamalpur Sadar', 'Islampur', 'Dewanganj', 'Baksiganj', 'Madarganj',
    'Melandaha', 'Sarishabari',
  ],
  'Netrokona': [
    'Netrokona Sadar', 'Atpara', 'Barhatta', 'Durgapur', 'Khaliajuri',
    'Kalmakanda', 'Kendua', 'Madan', 'Mohanganj', 'Purbadhala',
  ],
  'Sherpur': [
    'Sherpur Sadar', 'Jhenaigati', 'Nakla', 'Nalitabari', 'Sreebardi',
  ],
};

/// Ordered list of all 64 districts (city dropdown source).
final List<String> kBdDistricts = kBdLocations.keys.toList();
