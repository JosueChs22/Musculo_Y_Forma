
const mongoose = require('mongoose');

// ==========================================
// MODELO ANUNCIOS - SPRINT 3
// Compatible con la base de datos del equipo
// ==========================================

const anuncioSchema = new mongoose.Schema({

  titulo: {
    type: String,
    required: true,
    trim: true,
    maxlength: 150
  },

  contenido: {
    type: String,
    required: true,
    trim: true,
    maxlength: 5000
  },

  imagen: {
    type: String,
    default: null
  },

  clasificacion: {
    type: String,
    default: null,
    trim: true,
    maxlength: 60
  },

  fecha_publicacion: {
    type: Date,
    required: true
  },

  fecha_fin: {
    type: Date,
    default: null
  },

  estado: {
    type: String,
    enum: ['Activo', 'Inhabilitado'],
    default: 'Activo'
  }

}, {
  // La BD del equipo no admite campos adicionales
  versionKey: false,
  timestamps: false,
  collection: 'anuncios'
});

// Validar las fechas
anuncioSchema.path('fecha_fin').validate(function (value) {
  if (!value) return true;

  return !this.fecha_publicacion ||
    value >= this.fecha_publicacion;

}, 'La fecha de finalización no puede ser anterior a la publicación');

// Exportar modelo
module.exports = mongoose.model('Anuncio', anuncioSchema);
