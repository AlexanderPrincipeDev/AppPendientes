#!/usr/bin/env python3

import os
import math

def create_svg_icon(size):
    # Color azul de iOS
    bg_color = "#007AFF"
    
    # Calcular dimensiones proporcionales
    margin = size * 0.15
    checkbox_size = size * 0.06
    line_height = size * 0.03
    spacing = size * 0.18
    corner_radius = size * 0.125
    
    svg_content = f'''<?xml version="1.0" encoding="UTF-8"?>
<svg width="{size}" height="{size}" viewBox="0 0 {size} {size}" xmlns="http://www.w3.org/2000/svg">
  <!-- Fondo azul con esquinas redondeadas -->
  <rect width="{size}" height="{size}" rx="{corner_radius}" fill="{bg_color}"/>
  
  <!-- Elementos de lista de tareas -->
  <g fill="white">'''
    
    # Agregar 3 elementos de lista
    for i in range(3):
        y = margin + i * spacing
        
        # Checkbox
        checkbox_y = y
        checkbox_rx = checkbox_size * 0.15
        
        # Línea de texto
        text_x = margin + checkbox_size + margin * 0.5
        text_y = y + (checkbox_size - line_height) * 0.5
        text_width = size - text_x - margin
        text_rx = line_height * 0.25
        
        svg_content += f'''
    <!-- Item {i + 1} -->
    <rect x="{margin}" y="{checkbox_y}" width="{checkbox_size}" height="{checkbox_size}" rx="{checkbox_rx}"/>
    <rect x="{text_x}" y="{text_y}" width="{text_width}" height="{line_height}" rx="{text_rx}"/>'''
    
    svg_content += '''
  </g>
</svg>'''
    
    return svg_content

# Crear iconos SVG para todos los tamaños
sizes = [20, 40, 58, 60, 80, 87, 120, 180, 1024]

for size in sizes:
    svg_content = create_svg_icon(size)
    with open(f'icon-{size}.svg', 'w') as f:
        f.write(svg_content)
    print(f'Creado icon-{size}.svg')

print('SVGs creados. Convirtiendo a PNG...')
