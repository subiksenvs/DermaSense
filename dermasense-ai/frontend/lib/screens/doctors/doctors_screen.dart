import 'package:flutter/material.dart';

class DoctorsScreen extends StatelessWidget {
  const DoctorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Consult Dermatologist"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: "Search doctors by name or specialization...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Map Placeholder
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    "Google Maps View (Demo)",
                    style: TextStyle(color: Colors.grey[600]),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "Available Specialists",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            _buildDoctorCard(
              context,
              "Dr. Emily Chen",
              "Dermatologist (Acne & Pigmentation)",
              "12 Years Exp.",
              4.9,
              "\$120",
              "Available Today",
            ),
            const SizedBox(height: 12),
            _buildDoctorCard(
              context,
              "Dr. Marcus Johnson",
              "Cosmetic Dermatologist",
              "8 Years Exp.",
              4.7,
              "\$100",
              "Available Tomorrow",
            ),
            const SizedBox(height: 12),
            _buildDoctorCard(
              context,
              "Dr. Sophia Patel",
              "Clinical Dermatologist",
              "15 Years Exp.",
              4.9,
              "\$150",
              "Available Next Week",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard(BuildContext context, String name, String spec, String exp, double rating, String fee, String availability) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    spec,
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.work_outline, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(exp, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      const SizedBox(width: 12),
                      Icon(Icons.star, size: 14, color: Colors.orange[400]),
                      const SizedBox(width: 4),
                      Text(rating.toString(), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        fee,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Mock Booking
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Booking appointment (Demo Mode)")),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: Size.zero,
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        child: const Text("Book"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    availability,
                    style: TextStyle(color: Colors.green[600], fontSize: 12, fontWeight: FontWeight.w500),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
