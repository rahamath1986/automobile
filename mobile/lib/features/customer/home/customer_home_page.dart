import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CustomerHomePage extends ConsumerWidget {
  const CustomerHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MotoSaaS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.go('/customer/profile'),
            tooltip: 'Profile',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hero banner
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.indigo.shade900,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Find your perfect ride',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Category quick links
          const Text('Browse by category',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          Row(
            children: [
              _CategoryCard(
                label: 'Motorcycles',
                icon: Icons.two_wheeler,
                onTap: () => context.go('/catalog?category=Motorcycle'),
              ),
              const SizedBox(width: 10),
              _CategoryCard(
                label: 'Scooters',
                icon: Icons.electric_scooter,
                onTap: () => context.go('/catalog?category=Scooter'),
              ),
              const SizedBox(width: 10),
              _CategoryCard(
                label: 'Electric',
                icon: Icons.bolt,
                onTap: () => context.go('/catalog?fuelType=Electric'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // All vehicles
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/catalog'),
              icon: const Icon(Icons.search),
              label: const Text('Browse All Vehicles'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Icon(icon, size: 32, color: Colors.indigo),
              const SizedBox(height: 6),
              Text(label,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

