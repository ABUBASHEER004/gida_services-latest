import 'package:flutter/material.dart';
import 'package:gida_services/screens/service_providers_screen.dart';
import 'search_providers_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<Map<String, dynamic>> services = [
    {
      "name": "Waste Pickup",
      "icon": Icons.delete,
    },
     {
      "name": "Tailor",
      "icon": Icons.man,
    },
     {
      "name": "Shoe Seller",
      "icon": Icons.man,
    },
    {
      "name": "Vegetables and Kayan Miya",
      "icon": Icons.grass,
    },
    {
      "name": "Meat Seller",
      "icon": Icons.restaurant,
    },
    {
      "name": "Plumber",
      "icon": Icons.plumbing,
    },
    {
      "name": "Electrician",
      "icon": Icons.electrical_services,
    },
    {
      "name": "Carpenter",
      "icon": Icons.carpenter,
    },
    {
      "name": "Phone Repair",
      "icon": Icons.man_2,
    },
    {
      "name": "Wielding",
      "icon": Icons.home_repair_service,
    },
     {
      "name": "Car Wash",
      "icon": Icons.local_car_wash,
    },
     {
      "name": "Gardener",
      "icon": Icons.man_2,
    },
     {
      "name": "Gas refill",
      "icon": Icons.gas_meter,
    },
     {
      "name": "P.o.s Agent",
      "icon": Icons.man_2,
    },
    {
      "name": "Car Repair",
      "icon": Icons.car_repair,
    },
    {
      "name": "Cleaning",
      "icon": Icons.cleaning_services,
    },
    {
      "name": "Laundry",
      "icon": Icons.local_laundry_service,
    },
    {
      "name": "Food Delivery",
      "icon": Icons.delivery_dining,
    },
    {
      "name": "Lesson Teacher",
      "icon": Icons.book,
    },
   {
      "name": "Book Barbing Queue",
      "icon": Icons.man_2
    },
    {
      "name": "Mai Kitso",
      "icon": Icons.woman,
    },
    {
      "name": "Mai Lalle",
      "icon": Icons.woman_2,
    },
    {
      "name": "Book Saloon Queue",
      "icon": Icons.woman,
    },
    {
      "name": "Fish Seller",
      "icon": Icons.woman,
    },
    {
      "name": "Painter",
      "icon": Icons.man_2,
    },
    {
      "name": "Delivery Services",
      "icon": Icons.man,
    },
    {
      "name": "Order Snacks",
      "icon": Icons.woman_2,
    },
     {
      "name":"Napep Booking",
      "icon": Icons.man_2,
    },

    {
      "name":"Electronic Appliances Repair",
    "icon": Icons.electrical_services,
    },
    {
      "name":"Animal Clinic",
    "icon": Icons.local_hospital,
    },
    {
      "name":"Chicken Booking, Feeds and Drugs",
    "icon": Icons.man_2,
    },
    {
      "name":"Diagnostic Centre",
    "icon": Icons.local_hospital_outlined,
    },
    {
      "name":"Hospital",
    "icon": Icons.local_hospital,
    },
    {
      "name":"Building Materials",
    "icon": Icons.man,
    },
    {
      "name":"Plumbing Materials Seller",
    "icon": Icons.man_2,
    },
    {
      "name":"Carpentry Materials Seller",
    "icon": Icons.man_2,
    },
    {
      "name":"Cement Seller",
      "icon": Icons.man_2,
    },
    {
      "name":"Pharmacy",
    "icon": Icons.local_pharmacy,
    },
    {
      "name":"Fabrics(shadda/yadi) Dealer ",
    "icon": Icons.man_2,
    },
    {
      "name":"Abaya Seller",
    "icon": Icons.woman_2,
    },
    {
      "name":"Football Kits Seller",
    "icon": Icons.man_2,
    },
    {
      "name":"Kitchen Utensils Seller",
    "icon": Icons.woman_2,
    },
    {
      "name":"Restaurant",
    "icon": Icons.restaurant,
    },
    {
      "name":"Graphic Designer",
    "icon": Icons.man_2,
    },
    {
      "name":"Building Labourer",
    "icon": Icons.man_2,
    },
    {
      "name":"Construction Firms",
    "icon": Icons.construction,
    },
    {
      "name":"Real Estate Agent",
    "icon": Icons.man_2,
    },
    {
      "name":"Pure Water Distributor",
    "icon": Icons.man_2,
    },
    {
      "name":"Cloths/Baby Cloths Seller",
    "icon": Icons.woman_2,
    },
    {
      "name":"Make-up Saloon",
    "icon": Icons.woman_2,
    },
    {
      "name":"Printing, Writing and Reading Materials(Books)",
    "icon": Icons.woman_2,
    },
    {
      "name":"Electronic Appliances Seller",
    "icon": Icons.woman_2,
    },
    {
      "name":"Provision Store",
    "icon": Icons.man_2,
    },
    {
      "name":"Islamic Lesson Teacher",
    "icon": Icons.man_2,
    },
    {
      "name":"Beds Seller",
    "icon": Icons.bed,
    },
    {
      "name":"Furniture Seller",
    "icon": Icons.chair,
    },
    {
      "name":"Suya Spot",
    "icon": Icons.man_2,
    },
    {
      "name":"Animals Seller",
    "icon": Icons.man,
    },
    {
      "name":"Rice Seller",
    "icon": Icons.woman_2,
    },
    {
      "name":"Grain Seller",
    "icon": Icons.man_2,
    },
    {
      "name":"Yam Seller",
    "icon": Icons.man_2,
    },
    {
      "name":"Fruits Seller",
    "icon": Icons.man_2,
    },
    {
      "name":"Rubber Home Equipment Seller",
    "icon": Icons.woman_2,
    },
    {
      "name":"Palm oil/Groundnut oil Seller",
    "icon": Icons.woman_2,
    },
    {
      "name":"Petrol Black Marketer",
    "icon": Icons.man_2,
    },
    {
      "name":"Women Beauty Products Seller",
    "icon": Icons.woman_2,
    },
    {
      "name":"School",
    "icon": Icons.school,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text("Gida Services"),
  centerTitle: true,
  actions: [
    IconButton(
      icon: const Icon(Icons.search),
      tooltip: "Search Providers",
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SearchProvidersScreen(),
          ),
        );
      },
    ),
  ],
),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: services.length,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1.1,
          ),
          itemBuilder: (context, index) {
            final service = services[index];

            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ServiceProvidersScreen(
                      category: service["name"] as String,
                    ),
                  ),
                );
              },
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      service["icon"] as IconData,
                      size: 50,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        service["name"] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


