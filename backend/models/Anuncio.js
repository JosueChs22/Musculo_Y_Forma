const mongoose = require('mongoose');

const anuncioSchema = new mongoose.Schema({
  titulo: { type: String, required: true, trim: true, maxlength: 150 },
  contenido: { type: String, required: true, trim: true, maxlength: 5000 },
  imagen: { type: String, default: null },
  categoria: { type: String, required: true, trim: true, maxlength: 60 },
  fechaPublicacion: { type: Date, required: true },
  fechaFinalizacion: { type: Date, required: true },
  estado: { type: String, enum: ['Activo', 'Inhabilitado'], default: 'Activo' },
}, { timestamps: { createdAt: 'fechaCreacion', updatedAt: 'fechaActualizacion' } });

anuncioSchema.path('fechaFinalizacion').validate(function (value) {
  return !this.fechaPublicacion || value >= this.fechaPublicacion;
}, 'La fecha de finalización no puede ser anterior a la publicación');

module.exports = mongoose.model('Anuncio', anuncioSchema);
