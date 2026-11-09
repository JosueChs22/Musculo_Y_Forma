function errorHandler(err, req, res, _next) {
  console.error('[Error]', err.message);

  // Validación de esquema MongoDB
  if (err.code === 121) {
    return res.status(422).json({ error: 'Datos inválidos según el esquema', detail: err.errInfo?.details });
  }
  // ObjectId mal formado
  if (err.name === 'BSONError') {
    return res.status(400).json({ error: 'ID mal formado' });
  }

  res.status(500).json({ error: 'Error interno del servidor' });
}

module.exports = errorHandler;
