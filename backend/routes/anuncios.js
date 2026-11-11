
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

// ==========================================
// CONFIGURACIÓN DE IMÁGENES
// ==========================================

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
      clasificacion,
      fecha_publicacion,
      fecha_fin
    } = req.body;

    if (![titulo, contenido, fecha_publicacion, fecha_fin]
      .every(v => typeof v === 'string' && v.trim())) {
      borrarArchivo(req.file);

      return res.status(400).json({
        mensaje: 'Complete título, contenido y fechas'
      });
    }

    if (clasificacion !== undefined &&
        (typeof clasificacion !== 'string' || !clasificacion.trim())) {
      borrarArchivo(req.file);
      return res.status(400).json({
        mensaje: 'La clasificación no es válida'
      });
    }

    const inicio = new Date(fecha_publicacion);
    const fin = new Date(fecha_fin);

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
      clasificacion: clasificacion?.trim() || null,
      fecha_publicacion: inicio,
      fecha_fin: fin,
      estado: 'Activo',
      imagen: req.file ? `/uploads/${req.file.filename}` : null
    });

    res.status(201).json({
      mensaje: 'Anuncio publicado correctamente',
      anuncio
    });

  } catch (error) {
    borrarArchivo(req.file);

    if (error.name === 'ValidationError') {
      return res.status(400).json({
        mensaje: error.message
      });
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
      fecha_publicacion: { $lte: ahora },
      $or: [
        { fecha_fin: { $gte: ahora } },
        { fecha_fin: null }
      ]
    }).sort({ fecha_publicacion: -1 });

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
      .sort({ fecha_publicacion: -1 });

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
      clasificacion,
      fecha_publicacion,
      fecha_fin
    } = req.body;

    // Validar campos de texto
    for (const valor of [titulo, contenido]) {
      if (valor !== undefined &&
          (typeof valor !== 'string' || !valor.trim())) {
        borrarArchivo(req.file);

        return res.status(400).json({
          mensaje: 'El título y contenido no pueden estar vacíos'
        });
      }
    }

    if (clasificacion !== undefined &&
        (typeof clasificacion !== 'string' || !clasificacion.trim())) {
      borrarArchivo(req.file);

      return res.status(400).json({
        mensaje: 'La clasificación no es válida'
      });
    }

    const inicio = fecha_publicacion !== undefined
      ? new Date(fecha_publicacion)
      : anuncio.fecha_publicacion;

    const fin = fecha_fin !== undefined
      ? new Date(fecha_fin)
      : anuncio.fecha_fin;

    if (
      Number.isNaN(inicio.getTime()) ||
      (fin && Number.isNaN(fin.getTime())) ||
      (fin && fin < inicio)
    ) {
      borrarArchivo(req.file);

      return res.status(400).json({
        mensaje: 'Las fechas de vigencia no son válidas'
      });
    }

    if (titulo !== undefined) anuncio.titulo = titulo.trim();
    if (contenido !== undefined) anuncio.contenido = contenido.trim();
    if (clasificacion !== undefined) {
      anuncio.clasificacion = clasificacion.trim();
    }

    anuncio.fecha_publicacion = inicio;
    anuncio.fecha_fin = fin;

    const imagenAnterior = anuncio.imagen;

    if (req.file) {
      anuncio.imagen = `/uploads/${req.file.filename}`;
    }

    await anuncio.save();

    // Eliminar imagen anterior después de guardar
    if (req.file && imagenAnterior?.startsWith('/uploads/')) {
      fs.unlink(
        path.join(uploadDir, path.basename(imagenAnterior)),
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

    if (!mongoose.isObjectIdOrHexString(id)) {
      return res.status(400).json({
        mensaje: 'El ID del anuncio no es válido'
      });
    }

    const anuncio = await Anuncio.findById(id);

    if (!anuncio) {
      return res.status(404).json({
        mensaje: 'Anuncio no encontrado'
      });
    }

    if (anuncio.estado === 'Inhabilitado') {
      return res.status(409).json({
        mensaje: 'El anuncio ya está inhabilitado'
      });
    }

    // Cambiar estado sin eliminar el documento
    anuncio.estado = 'Inhabilitado';

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
// MANEJO DE ERRORES DE ARCHIVOS
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
