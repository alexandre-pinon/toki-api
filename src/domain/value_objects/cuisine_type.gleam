pub type CuisineType {
  Chinese
  Japanese
  Korean
  Vietnamese
  Thai
  Indian
  Indonesian
  Malaysian
  Filipino
  Singaporean
  Taiwanese
  Tibetan
  Nepalese
  Italian
  French
  Spanish
  Greek
  German
  British
  Irish
  Portuguese
  Hungarian
  Polish
  Russian
  Swedish
  Norwegian
  Danish
  Dutch
  Belgian
  Swiss
  Austrian
  Turkish
  Lebanese
  Iranian
  Israeli
  Moroccan
  Egyptian
  Syrian
  Iraqi
  Saudi
  American
  Mexican
  Brazilian
  Peruvian
  Argentinian
  Colombian
  Venezuelan
  Caribbean
  Cuban
  Cajun
  Creole
  Canadian
  Ethiopian
  Nigerian
  SouthAfrican
  Kenyan
  Ghanaian
  Senegalese
  Tanzanian
  Other
}

pub fn to_string(cuisine_type: CuisineType) -> String {
  case cuisine_type {
    Chinese -> "chinese"
    Japanese -> "japanese"
    Korean -> "korean"
    Vietnamese -> "vietnamese"
    Thai -> "thai"
    Indian -> "indian"
    Indonesian -> "indonesian"
    Malaysian -> "malaysian"
    Filipino -> "filipino"
    Singaporean -> "singaporean"
    Taiwanese -> "taiwanese"
    Tibetan -> "tibetan"
    Nepalese -> "nepalese"
    Italian -> "italian"
    French -> "french"
    Spanish -> "spanish"
    Greek -> "greek"
    German -> "german"
    British -> "british"
    Irish -> "irish"
    Portuguese -> "portuguese"
    Hungarian -> "hungarian"
    Polish -> "polish"
    Russian -> "russian"
    Swedish -> "swedish"
    Norwegian -> "norwegian"
    Danish -> "danish"
    Dutch -> "dutch"
    Belgian -> "belgian"
    Swiss -> "swiss"
    Austrian -> "austrian"
    Turkish -> "turkish"
    Lebanese -> "lebanese"
    Iranian -> "iranian"
    Israeli -> "israeli"
    Moroccan -> "moroccan"
    Egyptian -> "egyptian"
    Syrian -> "syrian"
    Iraqi -> "iraqi"
    Saudi -> "saudi"
    American -> "american"
    Mexican -> "mexican"
    Brazilian -> "brazilian"
    Peruvian -> "peruvian"
    Argentinian -> "argentinian"
    Colombian -> "colombian"
    Venezuelan -> "venezuelan"
    Caribbean -> "caribbean"
    Cuban -> "cuban"
    Cajun -> "cajun"
    Creole -> "creole"
    Canadian -> "canadian"
    Ethiopian -> "ethiopian"
    Nigerian -> "nigerian"
    SouthAfrican -> "southAfrican"
    Kenyan -> "kenyan"
    Ghanaian -> "ghanaian"
    Senegalese -> "senegalese"
    Tanzanian -> "tanzanian"
    Other -> "other"
  }
}

pub fn from_string(cuisine_type: String) -> CuisineType {
  case cuisine_type {
    "chinese" -> Chinese
    "japanese" -> Japanese
    "korean" -> Korean
    "vietnamese" -> Vietnamese
    "thai" -> Thai
    "indian" -> Indian
    "indonesian" -> Indonesian
    "malaysian" -> Malaysian
    "filipino" -> Filipino
    "singaporean" -> Singaporean
    "taiwanese" -> Taiwanese
    "tibetan" -> Tibetan
    "nepalese" -> Nepalese
    "italian" -> Italian
    "french" -> French
    "spanish" -> Spanish
    "greek" -> Greek
    "german" -> German
    "british" -> British
    "irish" -> Irish
    "portuguese" -> Portuguese
    "hungarian" -> Hungarian
    "polish" -> Polish
    "russian" -> Russian
    "swedish" -> Swedish
    "norwegian" -> Norwegian
    "danish" -> Danish
    "dutch" -> Dutch
    "belgian" -> Belgian
    "swiss" -> Swiss
    "austrian" -> Austrian
    "turkish" -> Turkish
    "lebanese" -> Lebanese
    "iranian" -> Iranian
    "israeli" -> Israeli
    "moroccan" -> Moroccan
    "egyptian" -> Egyptian
    "syrian" -> Syrian
    "iraqi" -> Iraqi
    "saudi" -> Saudi
    "american" -> American
    "mexican" -> Mexican
    "brazilian" -> Brazilian
    "peruvian" -> Peruvian
    "argentinian" -> Argentinian
    "colombian" -> Colombian
    "venezuelan" -> Venezuelan
    "caribbean" -> Caribbean
    "cuban" -> Cuban
    "cajun" -> Cajun
    "creole" -> Creole
    "canadian" -> Canadian
    "ethiopian" -> Ethiopian
    "nigerian" -> Nigerian
    "southAfrican" -> SouthAfrican
    "kenyan" -> Kenyan
    "ghanaian" -> Ghanaian
    "senegalese" -> Senegalese
    "tanzanian" -> Tanzanian
    _ -> Other
  }
}
