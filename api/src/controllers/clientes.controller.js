const service = require('../services/clientes.service');
const { usuarioResumenDto } = require('../views/rutina.dto');

async function buscar(req, res, next) {
  try {
    const limite = Math.min(parseInt(req.query.limite) || 20, 100);
    const q = typeof req.query.q === 'string' ? req.query.q.trim().slice(0, 80) : '';
    const cursor = typeof req.query.cursor === 'string' ? req.query.cursor : null;

    const r = await service.buscarClientes({ q, limite, cursor });
    res.json({ data: r.items.map(usuarioResumenDto), nextCursor: r.nextCursor });
  } catch (err) { next(err); }
}

module.exports = { buscar };
