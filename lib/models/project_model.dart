import 'package:flutter/material.dart';
import 'package:nixsvg/models/vector_shape.dart';

/// Represents a vector design project in nixSVG with metadata, canvas settings,
/// and collection of vector shapes.
class ProjectModel {
  final String id;
  final String name;
  final DateTime lastModified;
  final DateTime createdAt;
  final List<VectorShape> shapes;
  final Size canvasSize;

  ProjectModel({
    required this.id,
    required this.name,
    required this.lastModified,
    DateTime? createdAt,
    required this.shapes,
    this.canvasSize = const Size(1920, 1080),
  }) : createdAt = createdAt ?? lastModified;

  /// Creates a clean blank project with the specified name and canvas dimensions.
  factory ProjectModel.createNew({
    String? name,
    Size? size,
    List<VectorShape>? shapes,
  }) {
    final now = DateTime.now();
    return ProjectModel(
      id: 'proj-${now.millisecondsSinceEpoch}',
      name: name ?? 'Untitled Design',
      lastModified: now,
      createdAt: now,
      canvasSize: size ?? const Size(1920, 1080),
      shapes: shapes ?? [],
    );
  }

  /// Creates the signature nixSVG sample artwork with cards, star, ellipse, and typography.
  factory ProjectModel.sampleProject() {
    final now = DateTime.now();
    return ProjectModel(
      id: 'proj-sample-artwork',
      name: 'Sample Vector Artwork',
      lastModified: now,
      createdAt: now,
      canvasSize: const Size(1920, 1080),
      shapes: [
        VectorShape(
          id: 'shape-1',
          name: 'Background Card',
          type: ShapeType.roundedRectangle,
          rect: const Rect.fromLTWH(200, 150, 480, 280),
          fillColor: const Color(0xFF1E293B),
          fillOpacity: 0.9,
          strokeColor: const Color(0xFF6366F1),
          strokeWidth: 2.0,
          isStroked: true,
          cornerRadius: 20.0,
        ),
        VectorShape(
          id: 'shape-2',
          name: 'Accent Star',
          type: ShapeType.star,
          rect: const Rect.fromLTWH(580, 180, 70, 70),
          fillColor: const Color(0xFFF59E0B),
          strokeColor: const Color(0xFFFBBF24),
          isStroked: true,
        ),
        VectorShape(
          id: 'shape-3',
          name: 'Hero Logo Ellipse',
          type: ShapeType.ellipse,
          rect: const Rect.fromLTWH(240, 190, 80, 80),
          fillColor: const Color(0xFF6366F1),
          strokeColor: const Color(0xFF818CF8),
          strokeWidth: 3.0,
          isStroked: true,
        ),
        VectorShape(
          id: 'shape-4',
          name: 'Title Text',
          type: ShapeType.text,
          rect: const Rect.fromLTWH(340, 205, 280, 50),
          textContent: 'Vector Studio',
          fontSize: 32.0,
          fontFamily: 'Inter',
          isBold: true,
          fontWeight: FontWeight.w800,
          fillColor: Colors.white,
        ),
      ],
    );
  }

  ProjectModel copyWith({
    String? id,
    String? name,
    DateTime? lastModified,
    DateTime? createdAt,
    List<VectorShape>? shapes,
    Size? canvasSize,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      lastModified: lastModified ?? this.lastModified,
      createdAt: createdAt ?? this.createdAt,
      shapes: shapes ?? this.shapes.map((s) => s.copyWith()).toList(),
      canvasSize: canvasSize ?? this.canvasSize,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lastModified': lastModified.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'canvasWidth': canvasSize.width,
      'canvasHeight': canvasSize.height,
      'shapes': shapes.map((s) => s.toJson()).toList(),
    };
  }

  /// Ensures all image shapes within this project have their [decodedImage] decoded.
  Future<void> ensureAllImagesDecoded({VoidCallback? onImageDecoded}) async {
    for (final shape in shapes) {
      if (shape.type == ShapeType.image &&
          shape.decodedImage == null &&
          shape.imageBytes != null &&
          shape.imageBytes!.isNotEmpty) {
        await shape.ensureImageDecoded(onDecoded: onImageDecoded);
      }
    }
  }

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    final project = ProjectModel(
      id:
          json['id'] as String? ??
          'proj-${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Untitled Design',
      lastModified:
          DateTime.tryParse(json['lastModified'] as String? ?? '') ??
          DateTime.now(),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      canvasSize: Size(
        (json['canvasWidth'] as num?)?.toDouble() ?? 1920.0,
        (json['canvasHeight'] as num?)?.toDouble() ?? 1080.0,
      ),
      shapes:
          (json['shapes'] as List<dynamic>?)
              ?.map(
                (e) =>
                    VectorShape.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList() ??
          [],
    );
    project.ensureAllImagesDecoded();
    return project;
  }
}
