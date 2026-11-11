
const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const mongoose = require('mongoose');
const Anuncio = require('../models/Anuncio');

const router = express.Router();
const uploadDir = path.join(__dirname, '..', 'uploads');

fs.mkdirSync(uploadDir, { recursive: true });

// Configuración para subir imágenes
const upload = multer({
  storage: multer.diskStorage({
    destination: (_req, _file, cb) => cb(null, uploadDir),
    filename: (_req, file, cb) => {
      const nombre = `${Date.now()}-${crypto.randomBytes(8).toString('hex')}${path.extname(file.originalname).toLowerCase()}`;
      cb(null, nombre);
    }
  }),
  limits: { fileSize: 3 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const permitidos = ['image/jpeg', 'image/png', 'image/webp'];

    if (!permitidos.includes(file.mimetype)) {
      return cb(new Error('Solo se permiten imágenes JPG, PNG o WebP'));
    }

    cb(null, true);
  }
});

// Eliminar una imagen temporal si ocurre un error
const borrarArchivo = (file) => {
  if (file?.path) {
    fs.unlink(file.path, () => {});
  }
};

// ==========================================
// GYM-67 / RF-017: CREAR ANUNCIOS
// ==========================================

router.post('/', upload.single('imagen'), async (req, res) => {
  try {
    const {
      titulo,
      contenido,
      categoria,
      fechaPublicacion,
      fechaFinalizacion
    } = req.body;

    if (![titulo, contenido, categoria, fechaPublicacion, fechaFinalizacion]
      .every(v => typeof v === 'string' && v.trim())) {
      borrarArchivo(req.file);

      return res.status(400).json({
        mensaje: 'Complete título, contenido, categoría y fechas'
      });
    }

    const inicio = new Date(fechaPublicacion);
    const fin = new Date(fechaFinalizacion);

    if (
      Number.isNaN(inicio.getTime()) ||
      Number.isNaN(fin.getTime()) ||
      fin < inicio
    ) {
      borrarArchivo(req.file);

      return res.status(400).json({
        mensaje: 'Las fechas de vigencia no son válidas'
      });
    }

    const anuncio = await Anuncio.create({
      titulo: titulo.trim(),
      contenido: contenido.trim(),
      categoria: categoria.trim(),
      fechaPublicacion: inicio,
      fechaFinalizacion: fin,
      imagen: req.file ? `/uploads/${req.file.filename}` : null
    });

    res.status(201).json({
      mensaje: 'Anuncio publicado correctamente',
      anuncio
    });

  } catch (error) {
    borrarArchivo(req.file);

    if (error.name === 'ValidationError') {
      return res.status(400).json({ mensaje: error.message });
    }

    console.error('Error al crear anuncio:', error);

    res.status(500).json({
      mensaje: 'No se pudo crear el anuncio'
    });
  }
});

// ==========================================
// LISTAR ANUNCIOS PUBLICADOS
// ==========================================

router.get('/publicados', async (_req, res) => {
  try {
    const ahora = new Date();

    const anuncios = await Anuncio.find({
      estado: 'Activo',
      fechaPublicacion: { $lte: ahora },
      fechaFinalizacion: { $gte: ahora }
    }).sort({ fechaPublicacion: -1 });

    res.json(anuncios);

  } catch (error) {
    console.error('Error al listar anuncios:', error);

    res.status(500).json({
      mensaje: 'No se pudieron consultar los anuncios'
    });
  }
});

// ==========================================
// LISTAR TODOS LOS ANUNCIOS
// ==========================================

router.get('/', async (_req, res) => {
  try {
    const anuncios = await Anuncio.find()
      .sort({ fechaCreacion: -1 });

    res.json(anuncios);

  } catch (error) {
    console.error('Error al consultar anuncios:', error);

    res.status(500).json({
      mensaje: 'No se pudieron consultar los anuncios'
    });
  }
});

// ==========================================
// GYM-72 / RF-022: ACTUALIZAR ANUNCIOS
// ==========================================

router.put('/:id', upload.single('imagen'), async (req, res) => {
  try {
    const { id } = req.params;

    // Validar el identificador de MongoDB
    if (!mongoose.isObjectIdOrHexString(id)) {
      borrarArchivo(req.file);

      return res.status(400).json({
        mensaje: 'El ID del anuncio no es válido'
      });
    }

    const anuncio = await Anuncio.findById(id);

    if (!anuncio) {
      borrarArchivo(req.file);

      return res.status(404).json({
        mensaje: 'Anuncio no encontrado'
      });
    }

    const {
      titulo,
      contenido,
      categoria,
      fechaPublicacion,
      fechaFinalizacion
    } = req.body;

    // Validar campos de texto cuando se envían
    for (const valor of [titulo, contenido, categoria]) {
      if (valor !== undefined &&
          (typeof valor !== 'string' || !valor.trim())) {
        borrarArchivo(req.file);

        return res.status(400).json({
          mensaje: 'Los campos de texto no pueden estar vacíos'
        });
      }
    }

    // Validar las fechas antes de modificar el anuncio
    const inicio = fechaPublicacion !== undefined
      ? new Date(fechaPublicacion)
      : anuncio.fechaPublicacion;

    const fin = fechaFinalizacion !== undefined
      ? new Date(fechaFinalizacion)
      : anuncio.fechaFinalizacion;

    if (
      Number.isNaN(inicio.getTime()) ||
      Number.isNaN(fin.getTime()) ||
      fin < inicio
    ) {
      borrarArchivo(req.file);

      return res.status(400).json({
        mensaje: 'Las fechas de vigencia no son válidas'
      });
    }

    // Actualizar información
    if (titulo !== undefined) anuncio.titulo = titulo.trim();
    if (contenido !== undefined) anuncio.contenido = contenido.trim();
    if (categoria !== undefined) anuncio.categoria = categoria.trim();

    anuncio.fechaPublicacion = inicio;
    anuncio.fechaFinalizacion = fin;

    const imagenAnterior = anuncio.imagen;

    if (req.file) {
      anuncio.imagen = `/uploads/${req.file.filename}`;
    }

    // Registrar fecha de actualización
    anuncio.fechaActualizacion = new Date();

    await anuncio.save();

    // Eliminar imagen antigua si fue reemplazada
    if (req.file && imagenAnterior?.startsWith('/uploads/')) {
      const nombreAnterior = path.basename(imagenAnterior);

      fs.unlink(
        path.join(uploadDir, nombreAnterior),
        () => {}
      );
    }

    res.json({
      mensaje: 'Anuncio actualizado correctamente',
      anuncio
    });

  } catch (error) {
    borrarArchivo(req.file);

    if (error.name === 'ValidationError') {
      return res.status(400).json({
        mensaje: error.message
      });
    }

    console.error('Error al actualizar anuncio:', error);

    res.status(500).json({
      mensaje: 'No se pudo actualizar el anuncio'
    });
  }
});

// ==========================================
 // GYM-77 / RF-027: INHABILITAR ANUNCIOS
 // ==========================================

router.patch('/:id/inhabilitar', async (req, res) => {
  try {
    const { id } = req.params;

    // Validar ID de MongoDB
    if (!mongoose.isObjectIdOrHexString(id)) {
      return res.status(400).json({
        mensaje: 'El ID del anuncio no es válido'
      });
    }

    // Buscar anuncio
    const anuncio = await Anuncio.findById(id);

    if (!anuncio) {
      return res.status(404).json({
        mensaje: 'Anuncio no encontrado'
      });
    }

    // Evitar inhabilitar dos veces
    if (anuncio.estado === 'Inhabilitado') {
      return res.status(409).json({
        mensaje: 'El anuncio ya se encuentra inhabilitado'
      });
    }

    // Inhabilitación lógica
    anuncio.estado = 'Inhabilitado';
    anuncio.fechaActualizacion = new Date();

    await anuncio.save();

    res.json({
      mensaje: 'Anuncio inhabilitado correctamente',
      anuncio
    });

  } catch (error) {
    console.error('Error al inhabilitar anuncio:', error);

    res.status(500).json({
      mensaje: 'No se pudo inhabilitar el anuncio'
    });
  }
});

// ==========================================
// MANEJO DE ERRORES DE IMÁGENES
// ==========================================

router.use((err, _req, res, _next) => {
  if (err instanceof multer.MulterError) {
    return res.status(400).json({
      mensaje: err.code === 'LIMIT_FILE_SIZE'
        ? 'La imagen no debe superar 3 MB'
        : err.message
    });
  }

  res.status(400).json({
    mensaje: err.message || 'Archivo inválido'
  });
});

module.exports = router;
