import 'poi.dart';
import 'tour.dart';

class TourDemoStop {
  const TourDemoStop({
    required this.name,
    required this.description,
    required this.lat,
    required this.lng,
  });

  final String name;
  final String description;
  final double lat;
  final double lng;

  Poi toPoi(int tourId, int index) {
    return Poi(
      id: tourId * 100 - index,
      name: name,
      description: description,
      latitude: lat,
      longitude: lng,
      category: 'tour_stop',
    );
  }
}

class TourDemoDetails {
  const TourDemoDetails({
    required this.tour,
    required this.oldPrice,
    required this.promoUntil,
    required this.included,
    required this.expectations,
    required this.dates,
    required this.stops,
    required this.contactPhone,
    required this.installment,
  });

  final Tour tour;
  final double oldPrice;
  final String promoUntil;
  final List<String> included;
  final List<String> expectations;
  final Map<String, List<int>> dates;
  final List<TourDemoStop> stops;
  final String contactPhone;
  final String installment;

  List<Poi> get routePois {
    return [
      for (var i = 0; i < stops.length; i++) stops[i].toPoi(tour.id, i),
    ];
  }
}

const demoTourDetails = <TourDemoDetails>[
  TourDemoDetails(
    tour: Tour(
      id: -901,
      businessUserId: 0,
      title: 'Сон-Көл',
      description:
          'Озеро Сон-Көл, перевал Калмак-Ашуу, катание на лошадях, купание в озере, ночь в юрте и звездное небо на высоте около 3000 м.',
      durationDays: 2,
      price: 5990,
      distanceKm: 350,
      stopsCount: 5,
      difficulty: 'easy',
      isPublished: true,
    ),
    oldPrice: 7500,
    promoUntil: 'до 31 мая',
    included: [
      'трансфер',
      'питание: ужин, завтрак, обед',
      'проживание в юрте: 1 ночь',
      'услуги гида',
    ],
    expectations: [
      'перевал Калмак-Ашуу',
      'озеро Сон-Көл',
      'катание на лошадях',
      'купание в озере',
      'ночь в юрте',
      'звездное небо на высоте 3000 м',
    ],
    dates: {
      'Июнь': [6, 8, 10, 13, 15, 17, 20, 22, 24, 27, 29],
      'Июль': [1, 4, 6, 8, 11, 13, 15, 18, 20, 22, 25, 27, 29],
      'Август': [1, 3, 5, 8, 10, 12, 15, 17, 19, 22, 24, 26, 29, 31],
      'Сентябрь': [2, 5, 9, 12, 16, 19, 26],
    },
    stops: [
      TourDemoStop(
        name: 'Бишкек',
        description: 'Старт группы и выезд на трансфере.',
        lat: 42.8746,
        lng: 74.5698,
      ),
      TourDemoStop(
        name: 'Кочкор',
        description: 'Техническая остановка по дороге к озеру.',
        lat: 42.2155,
        lng: 75.7566,
      ),
      TourDemoStop(
        name: 'Перевал Калмак-Ашуу',
        description: 'Панорамная точка перед спуском к Сон-Көл.',
        lat: 41.9770,
        lng: 75.3370,
      ),
      TourDemoStop(
        name: 'Озеро Сон-Көл',
        description: 'Главная локация тура: озеро, юрты и прогулки.',
        lat: 41.8376,
        lng: 75.1490,
      ),
    ],
    contactPhone: '+996 776 332 330',
    installment: 'рассрочка 0% на 3 и 6 месяцев',
  ),
  TourDemoDetails(
    tour: Tour(
      id: -902,
      businessUserId: 0,
      title: 'Кел-Суу',
      description:
          'Высокогорное озеро Кел-Суу, долина Кок-Кыя, каньон реки Кок-Кыя и две ночи в юртах.',
      durationDays: 3,
      price: 9500,
      distanceKm: 520,
      stopsCount: 4,
      difficulty: 'medium',
      isPublished: true,
    ),
    oldPrice: 12500,
    promoUntil: 'до 31 мая',
    included: [
      'трансфер',
      'питание: 2 ужина, 2 завтрака, 1 ланч-бокс',
      'проживание в юртах: 2 ночи',
      'услуги гида',
    ],
    expectations: [
      'две ночи в юртах',
      'долина Кок-Кыя',
      'озеро Кел-Суу',
      'каньон реки Кок-Кыя',
    ],
    dates: {
      'Июнь': [22, 24, 26, 29],
      'Июль': [1, 3, 6, 8, 10, 13, 15, 17, 20, 22, 24, 27, 29, 31],
      'Август': [3, 5, 7, 10, 12, 14, 17, 19, 21, 24, 26, 28, 31],
      'Сентябрь': [2, 4, 9, 11, 16, 18, 23, 25],
    },
    stops: [
      TourDemoStop(
        name: 'Бишкек',
        description: 'Старт группы и выезд в Нарынскую область.',
        lat: 42.8746,
        lng: 74.5698,
      ),
      TourDemoStop(
        name: 'Нарын',
        description: 'Остановка по пути к приграничной зоне.',
        lat: 41.4287,
        lng: 75.9911,
      ),
      TourDemoStop(
        name: 'Долина Кок-Кыя',
        description: 'Юрточный лагерь и прогулки по долине.',
        lat: 40.6470,
        lng: 76.3080,
      ),
      TourDemoStop(
        name: 'Озеро Кел-Суу',
        description: 'Главная точка маршрута среди скал.',
        lat: 40.6400,
        lng: 76.3810,
      ),
    ],
    contactPhone: '+996 776 332 330',
    installment: 'рассрочка 0% на 3 и 6 месяцев',
  ),
  TourDemoDetails(
    tour: Tour(
      id: -903,
      businessUserId: 0,
      title: 'Ала-Көл',
      description:
          'Маршрут через ущелье Алтын-Арашан, горячие источники, подъем к озеру Ала-Көл и северный берег Иссык-Куля.',
      durationDays: 4,
      price: 14990,
      distanceKm: 430,
      stopsCount: 7,
      difficulty: 'hard',
      isPublished: true,
    ),
    oldPrice: 18000,
    promoUntil: 'до 31 мая',
    included: [
      'трансфер',
      'спецтрансфер Safari Tour',
      'питание: 2 ужина, 2 завтрака, 1 обед',
      'проживание в юртах: 2 ночи',
      'подъем на лошади до озера',
      'услуги конюха',
      'услуги гида',
      'входные билеты',
    ],
    expectations: [
      'ущелье Алтын-Арашан',
      'подъем на лошади до озера',
      'горячие источники Арашана',
      'конные прогулки',
      'Safari Tour на КАМАЗ',
      'северный берег Иссык-Куля',
      'купание на пляже',
    ],
    dates: {
      'Июль': [3, 10, 17, 24, 31],
      'Август': [7, 14, 21, 28],
      'Сентябрь': [4, 11],
    },
    stops: [
      TourDemoStop(
        name: 'Бишкек',
        description: 'Старт группы и выезд в сторону Иссык-Куля.',
        lat: 42.8746,
        lng: 74.5698,
      ),
      TourDemoStop(
        name: 'Каракол',
        description: 'Старт горной части маршрута.',
        lat: 42.4907,
        lng: 78.3936,
      ),
      TourDemoStop(
        name: 'Ущелье Алтын-Арашан',
        description: 'Горячие источники и юрточный лагерь.',
        lat: 42.3764,
        lng: 78.5580,
      ),
      TourDemoStop(
        name: 'Озеро Ала-Көл',
        description: 'Высокогорное озеро и главная точка похода.',
        lat: 42.3172,
        lng: 78.5358,
      ),
      TourDemoStop(
        name: 'Северный берег Иссык-Куля',
        description: 'Пляж и отдых после горной части.',
        lat: 42.6260,
        lng: 77.0700,
      ),
    ],
    contactPhone: '+996 776 332 330',
    installment: 'рассрочка 0% на 3 и 6 месяцев',
  ),
];

TourDemoDetails? demoDetailsForTour(Tour tour) {
  for (final details in demoTourDetails) {
    if (details.tour.id == tour.id ||
        details.tour.title.toLowerCase() == tour.title.toLowerCase()) {
      return details;
    }
  }
  return null;
}
