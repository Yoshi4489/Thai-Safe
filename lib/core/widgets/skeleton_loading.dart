import 'package:flutter/material.dart';

class SkeletonLoading extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLoading({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius,
  });

  @override
  State<SkeletonLoading> createState() => _SkeletonLoadingState();
}

class _SkeletonLoadingState extends State<SkeletonLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey[300]!,
                Colors.grey[200]!,
                Colors.grey[300]!,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton for stat cards
class SkeletonStatCard extends StatelessWidget {
  const SkeletonStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SkeletonLoading(width: 40, height: 30, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 4),
          SkeletonLoading(width: 60, height: 16, borderRadius: BorderRadius.circular(4)),
        ],
      ),
    );
  }
}

/// Skeleton for incident cards
class SkeletonIncidentCard extends StatelessWidget {
  const SkeletonIncidentCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SkeletonLoading(
            width: 50,
            height: 50,
            borderRadius: BorderRadius.circular(25),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoading(width: double.infinity, height: 18),
                const SizedBox(height: 8),
                SkeletonLoading(width: 150, height: 14),
                const SizedBox(height: 4),
                SkeletonLoading(width: 100, height: 12),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SkeletonLoading(width: 20, height: 20, borderRadius: BorderRadius.circular(4)),
        ],
      ),
    );
  }
}

/// Skeleton for list tile (rescue approval, admin recent incidents)
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          SkeletonLoading(
            width: 40,
            height: 40,
            borderRadius: BorderRadius.circular(20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoading(width: double.infinity, height: 16),
                const SizedBox(height: 8),
                SkeletonLoading(width: 120, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for rescue approval card
class SkeletonRescueApprovalCard extends StatelessWidget {
  const SkeletonRescueApprovalCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoading(width: 150, height: 20),
          const SizedBox(height: 8),
          SkeletonLoading(width: 200, height: 16),
          const SizedBox(height: 8),
          SkeletonLoading(width: 180, height: 14),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: SkeletonLoading(height: 40, borderRadius: BorderRadius.circular(8))),
              const SizedBox(width: 10),
              Expanded(child: SkeletonLoading(height: 40, borderRadius: BorderRadius.circular(8))),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton for incident management card
class SkeletonIncidentManagementCard extends StatelessWidget {
  const SkeletonIncidentManagementCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoading(width: 200, height: 18),
          const SizedBox(height: 8),
          SkeletonLoading(width: double.infinity, height: 14),
          const SizedBox(height: 6),
          SkeletonLoading(width: 150, height: 12),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLoading(width: 80, height: 30, borderRadius: BorderRadius.circular(8)),
              Row(
                children: [
                  SkeletonLoading(width: 40, height: 40, borderRadius: BorderRadius.circular(20)),
                  const SizedBox(width: 8),
                  SkeletonLoading(width: 40, height: 40, borderRadius: BorderRadius.circular(20)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
