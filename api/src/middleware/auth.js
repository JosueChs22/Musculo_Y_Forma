const jwt = require('jsonwebtoken');

function requerirAuth(req, res, next) {
  const [tipo, token] = (req.headers.authorization || '').split(' ');
  if (tipo !== 'Bearer' || !token) return res.status(401).json({ error: 'No autenticado' });
  try {
    const p = jwt.verify(token, process.env.JWT_SECRET, { algorithms: ['HS256'] });
    req.usuario = { id: p.sub, rol: p.rol };
    next();
  } catch {
    res.status(401).json({ error: 'Sesión inválida o expirada' });
  }
}

function requerirRol(...roles) {
  return (req, res, next) =>
    roles.includes(req.usuario?.rol)
      ? next()
      : res.status(403).json({ error: 'No tiene permiso para esta acción' });
}

module.exports = { requerirAuth, requerirRol };
