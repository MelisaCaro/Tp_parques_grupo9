"""
============================================================
  Integrantes: Caro, Melisa; Rolleri Villalba, Santino;
               Llanos, Franco;
  Fecha:       01/07/2026
  Descripcion: Aplicacion web Flask - Modulo de Ventas.
               Conecta con usr_ventas (rol_ventas).
               Funcionalidades:
                 - Alta: registrar venta de entrada (ARS o USD)
                   El tipo de cambio USD lo obtiene el SP
                   automaticamente desde dolarapi.com.
                   El nroTicket se genera automaticamente.
                 - Baja: listar tickets y anular

  Instalacion:
    pip install flask pyodbc
    pip install requests
    
  Ejecucion:
    python app_ventas.py
    Abrir http://localhost:5000
============================================================
"""

from flask import Flask, render_template_string, request, redirect, url_for, flash
from markupsafe import Markup
import pyodbc
from datetime import date

app = Flask(__name__)
app.secret_key = "parques_ventas_2026"

# ============================================================
# CONFIG
# ============================================================
DB_SERVER = "DESKTOP-SPRFOKE\\PARQUES_NAC"
DB_NAME   = "ParquesNacionalesDB"
DB_DRIVER = "ODBC Driver 17 for SQL Server"
DB_USER   = "usr_admin"
DB_PASS   = "Admin2026!"

CONN_STRING = (
    f"DRIVER={{{DB_DRIVER}}};"
    f"SERVER={DB_SERVER};"
    f"DATABASE={DB_NAME};"
    f"UID={DB_USER};PWD={DB_PASS};"
)

# ============================================================
# HELPERS
# ============================================================

def get_conn():
    return pyodbc.connect(CONN_STRING)


def consultar(sql, params=None):
    try:
        conn   = get_conn()
        cursor = conn.cursor()
        cursor.execute(sql, params or [])
        cols = [c[0] for c in cursor.description]
        rows = [dict(zip(cols, r)) for r in cursor.fetchall()]
        conn.close()
        return rows
    except Exception as e:
        print(f"ERROR CONSULTA: {e}")
        return []


def ejecutar_sp(sp, params=None):
    try:
        conn   = get_conn()
        cursor = conn.cursor()
        if params:
            placeholders = ", ".join(f"@{k}=?" for k in params)
            cursor.execute(f"EXEC {sp} {placeholders}", list(params.values()))
        else:
            cursor.execute(f"EXEC {sp}")
        try:
            cols = [c[0] for c in cursor.description]
            rows = [dict(zip(cols, r)) for r in cursor.fetchall()]
        except Exception:
            rows = []
        conn.commit()
        conn.close()
        return rows, None
    except pyodbc.Error as e:
        msg = str(e)
        if "[SQL Server]" in msg:
            msg = msg.split("[SQL Server]")[-1].strip()
        return [], msg


import requests as req_lib

def obtener_tipo_cambio():
    """
    Consulta dolarapi.com directamente.
    Retorna (tipoCambio, fuente) o (None, error).
    El SP sp_ObtenerTipoCambioDolar existe en la DB para
    demostrar la integracion; la app lo llama cuando el
    entorno lo permite (usuario SQL local). Con Azure AD
    se usa esta funcion como alternativa.
    """
    try:
        resp = req_lib.get("https://dolarapi.com/v1/dolares/blue", timeout=5)
        resp.raise_for_status()
        data = resp.json()
        return float(data["venta"]), "dolarapi.com - Dolar Blue"
    except Exception as e:
        return None, f"No se pudo obtener el tipo de cambio: {e}"


# ============================================================
# HELPERS: cargar combos
# ============================================================

def cargar_parques():
    """Solo parques con precio vigente para hoy."""
    return consultar("""
        SELECT DISTINCT p.idParque, p.nombre
        FROM parques.Parque p
        JOIN ventas.PrecioEntrada pe ON pe.idParque = p.idParque
        WHERE p.activo = 1
          AND pe.vigenciaDesde <= GETDATE()
          AND (pe.vigenciaHasta IS NULL OR pe.vigenciaHasta >= GETDATE())
        ORDER BY p.nombre
    """)

def cargar_puntos_venta():
    return consultar("""
        SELECT pv.idPuntoVenta, pv.idParque, p.nombre + ' - ' + pv.nombre AS descripcion
        FROM parques.PuntoVenta pv
        JOIN parques.Parque p ON p.idParque = pv.idParque
        WHERE pv.activo = 1
        ORDER BY p.nombre
    """)

def cargar_formas_pago():
    return consultar(
        "SELECT idFormaPago, descripcion FROM maestros.FormaPago ORDER BY descripcion"
    )

def cargar_tipos_visitante():
    return consultar(
        "SELECT idTipoVisitante, nombre FROM maestros.TipoVisitante ORDER BY idTipoVisitante"
    )


# ============================================================
# TEMPLATE BASE
# ============================================================

BASE_HTML = """
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Ventas - Parques Nacionales</title>
<style>
  body  { font-family: Arial, sans-serif; margin: 0; background: #f4f6f8; color: #222; }
  nav   { background: #1a5c2a; padding: 12px 24px; display: flex; gap: 20px; align-items: center; }
  nav a { color: #fff; text-decoration: none; font-weight: bold; font-size: 14px; }
  nav a:hover { text-decoration: underline; }
  nav .brand { color: #a8d5a2; font-size: 18px; margin-right: 20px; }
  nav .rol   { color: #a8d5a2; font-size: 12px; margin-left: auto; }
  .container { max-width: 900px; margin: 30px auto; padding: 0 20px; }
  h2  { color: #1a5c2a; border-bottom: 2px solid #1a5c2a; padding-bottom: 6px; }
  h3  { color: #1a5c2a; }
  .card { background: #fff; border-radius: 6px; padding: 20px; margin-bottom: 20px;
          box-shadow: 0 1px 4px rgba(0,0,0,.1); }
  .form-group { margin-bottom: 14px; }
  label { display: block; font-size: 13px; font-weight: bold; margin-bottom: 4px; }
  input, select { width: 100%; padding: 8px 10px; border: 1px solid #ccc;
                  border-radius: 4px; font-size: 13px; box-sizing: border-box; }
  .btn { display: inline-block; padding: 9px 20px; border-radius: 4px; font-size: 14px;
         cursor: pointer; border: none; font-weight: bold; text-decoration: none; }
  .btn-primary { background: #1a5c2a; color: #fff; }
  .btn-danger  { background: #c0392b; color: #fff; }
  .btn-info    { background: #2980b9; color: #fff; }
  .btn:hover   { opacity: .85; }
  .alert { padding: 12px 16px; border-radius: 4px; margin-bottom: 16px; font-size: 13px; }
  .alert-success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
  .alert-danger  { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
  .resultado { border-left: 4px solid #1a5c2a; padding: 16px 20px;
               background: #f0f8f0; border-radius: 0 6px 6px 0; margin-top: 20px; }
  .resultado table { width: auto; box-shadow: none; background: transparent; }
  .resultado td { padding: 5px 16px 5px 0; font-size: 14px; border: none; }
  .monto { font-size: 20px; font-weight: bold; color: #1a5c2a; }
  table { width: 100%; border-collapse: collapse; background: #fff; border-radius: 6px;
          overflow: hidden; box-shadow: 0 1px 4px rgba(0,0,0,.1); }
  th { background: #1a5c2a; color: #fff; padding: 10px 12px; text-align: left; font-size: 13px; }
  td { padding: 9px 12px; border-bottom: 1px solid #e8e8e8; font-size: 13px; }
  tr:last-child td { border-bottom: none; }
  .badge-ok  { background: #d4edda; color: #155724; padding: 2px 8px; border-radius: 10px;
               font-size: 11px; font-weight: bold; }
  .badge-err { background: #f8d7da; color: #721c24; padding: 2px 8px; border-radius: 10px;
               font-size: 11px; font-weight: bold; }
  .row { display: flex; gap: 20px; }
  .col { flex: 1; }
  .api-nota { background: #eaf4ea; border: 1px solid #a8d5a2; border-radius: 4px;
              padding: 8px 12px; font-size: 12px; color: #1a5c2a; margin-top: 6px; }
</style>
</head>
<body>
<nav>
  <span class="brand">&#127795; Parques Nacionales</span>
  <a href="/">&#10010; Nueva Venta</a>
  <a href="/tickets">&#128190; Tickets</a>
  <span class="rol">&#128100; usr_admin (rol_admin)</span>
</nav>
<div class="container">
{% with messages = get_flashed_messages(with_categories=true) %}
  {% for cat, msg in messages %}
    <div class="alert alert-{{ cat }}" style="white-space:pre-wrap">{{ msg }}</div>
  {% endfor %}
{% endwith %}
{{ content }}
</div>
</body>
</html>
"""

def render_page(content):
    return render_template_string(BASE_HTML, content=Markup(content))


# ============================================================
# RUTA: Alta — Nueva venta
# ============================================================

@app.route("/", methods=["GET", "POST"])
def nueva_venta():
    parques         = cargar_parques()
    puntos_venta    = cargar_puntos_venta()
    formas_pago     = cargar_formas_pago()
    tipos_visitante = cargar_tipos_visitante()
    resultado       = None

    if request.method == "POST":
        dni        = request.form["dni"].strip()
        nombre_vis = request.form["nombreVisitante"].strip()
        apellido   = request.form["apellido"].strip()
        id_tipo_vis = int(request.form["idTipoVisitante"])
        moneda     = request.form.get("moneda", "ARS")

        # Buscar o crear visitante por DNI
        visitantes = consultar(
            "SELECT idVisitante FROM ventas.Visitante WHERE dniPasaporte = ?", [dni]
        )
        if visitantes:
            id_visitante = visitantes[0]["idVisitante"]
            # Actualizar tipo por si cambio desde la ultima visita
            ejecutar_sp("sp_Visitante_Actualizar", {
                "idVisitante":     id_visitante,
                "idTipoVisitante": id_tipo_vis,
                "nombre":          nombre_vis,
                "apellido":        apellido,
                "dniPasaporte":    dni,
                "nacionalidad":    request.form.get("nacionalidad") or "Argentina",
            })
        else:
            rows, error = ejecutar_sp("sp_Visitante_Insertar", {
                "idTipoVisitante": id_tipo_vis,
                "nombre":          nombre_vis,
                "apellido":        apellido,
                "dniPasaporte":    dni,
                "nacionalidad":    request.form.get("nacionalidad") or "Argentina",
            })
            if error:
                flash(error, "danger")
                return redirect(url_for("nueva_venta"))
            id_visitante = rows[0]["idVisitante"] if rows else None

        if not id_visitante:
            flash("No se pudo registrar el visitante.", "danger")
            return redirect(url_for("nueva_venta"))

        # Registrar venta via sp_VentaEntradaSimple
        tipo_cambio   = 1
        fuente_tc     = None

        if moneda == "USD":
            tipo_cambio, fuente_tc = obtener_tipo_cambio()
            if not tipo_cambio:
                flash(f"No se pudo obtener el tipo de cambio: {fuente_tc}", "danger")
                return redirect(url_for("nueva_venta"))

        rows, error = ejecutar_sp("sp_VentaEntradaSimple", {
            "idPuntoVenta":     int(request.form["idPuntoVenta"]),
            "idFormaPago":      int(request.form["idFormaPago"]),
            "idVisitante":      id_visitante,
            "idParque":         int(request.form["idParque"]),
            "fechaAcceso":      request.form.get("fechaAcceso") or date.today().isoformat(),
            "moneda":           moneda,
            "tipoCambio":       tipo_cambio,
            "fuenteTipoCambio": fuente_tc,
        })
        if error:
            flash(error, "danger")
        elif rows:
            # sp_VentaEntradas devuelve idTicket, totalARS, totalUSD, tipoCambio, fuenteTipoCambio, resumen
            # Buscar el nroTicket del ticket recien creado por idTicket
            id_ticket_nuevo = rows[0].get("idTicket")
            ticket_info = consultar(
                "SELECT nroTicket, total, totalUSD, tipoCambio, fuenteTipoCambio FROM ventas.Ticket WHERE idTicket = ?",
                [id_ticket_nuevo]
            )
            if ticket_info:
                resultado = ticket_info[0]
                resultado["idTicket"] = id_ticket_nuevo
                resultado["moneda"]   = moneda
                resultado["moneda"] = moneda

    hoy     = date.today().isoformat()
    opts_pq = "".join(f'<option value="{p["idParque"]}">{p["nombre"]}</option>' for p in parques)

    # Generar opciones de puntos de venta con data-parque para filtrar con JS
    opts_pv_all = "".join(
        f'<option value="{pv["idPuntoVenta"]}" data-parque="{pv["idParque"]}">{pv["descripcion"]}</option>'
        for pv in puntos_venta
    )
    # JSON para el JS
    import json
    pv_json = json.dumps([{"id": pv["idPuntoVenta"], "idParque": pv["idParque"], "desc": pv["descripcion"]} for pv in puntos_venta])
    opts_pv = "".join(f'<option value="{pv["idPuntoVenta"]}">{pv["descripcion"]}</option>' for pv in puntos_venta)
    opts_fp = "".join(f'<option value="{f["idFormaPago"]}">{f["descripcion"]}</option>' for f in formas_pago)
    opts_tv = '<option value="">-- Seleccionar tipo --</option>' + "".join(
        f'<option value="{t["idTipoVisitante"]}">{t["nombre"]}</option>'
        for t in tipos_visitante
    )
    resultado_html = ""
    if resultado:
        if resultado["moneda"] == "USD" and resultado["totalUSD"]:
            monto_html = f"""
            <tr><td>Precio en ARS:</td>
                <td><span class="monto">$ {resultado['total']:,.2f} ARS</span></td></tr>
            <tr><td>El visitante paga en USD:</td>
                <td><span class="monto">USD {resultado['totalUSD']:,.2f}</span></td></tr>
            <tr><td>Tipo de cambio:</td>
                <td>$ {resultado['tipoCambio']:,.2f} ({resultado['fuenteTipoCambio']})</td></tr>"""
        else:
            monto_html = f"""
            <tr><td>Total:</td>
                <td><span class="monto">$ {resultado['total']:,.2f} ARS</span></td></tr>"""

        resultado_html = f"""
        <div class="resultado">
          <h3 style="margin-top:0">&#10003; Ticket N° {resultado['nroTicket']} registrado</h3>
          <table>{monto_html}</table>
        </div>"""

    content = f"""
    <h2>&#10010; Nueva Venta de Entrada</h2>
    <div class="card">
    <form method="POST">
      <h3 style="margin-top:0">Datos del Visitante</h3>
      <div class="row">
        <div class="col">
          <div class="form-group"><label>Nombre *</label>
            <input name="nombreVisitante" required></div>
          <div class="form-group"><label>Apellido *</label>
            <input name="apellido" required></div>
          <div class="form-group"><label>Nacionalidad</label>
            <input name="nacionalidad" value="Argentina"></div>
        </div>
        <div class="col">
          <div class="form-group"><label>DNI / Pasaporte *</label>
            <input name="dni" required></div>
          <div class="form-group"><label>Tipo de Visitante *</label>
            <select name="idTipoVisitante">{opts_tv}</select></div>
          <div class="form-group">
            <label>Moneda de Pago</label>
            <select name="moneda">
              <option value="ARS">ARS - Pesos Argentinos</option>
              <option value="USD">USD - Dolares</option>
            </select>
            <div class="api-nota">
              &#127760; Si selecciona USD, el tipo de cambio se obtiene
              automaticamente desde <strong>dolarapi.com</strong> al registrar la venta.
            </div>
          </div>
        </div>
      </div>
      <h3>Datos de la Entrada</h3>
      <div class="row">
        <div class="col">
          <div class="form-group"><label>Parque *</label>
            <select name="idParque" id="idParque" onchange="filtrarPuntosVenta()" required>
              <option value="">-- Seleccionar parque --</option>
              {opts_pq}
            </select></div>
          <div class="form-group"><label>Fecha de Acceso</label>
            <input type="date" name="fechaAcceso" value="{hoy}"></div>
        </div>
        <div class="col">
          <div class="form-group"><label>Punto de Venta *</label>
            <select name="idPuntoVenta" id="idPuntoVenta" required>
              <option value="">-- Primero seleccione un parque --</option>
            </select></div>
          <div class="form-group"><label>Forma de Pago *</label>
            <select name="idFormaPago">{opts_fp}</select></div>
        </div>
      </div>
      <button type="submit" class="btn btn-primary">Registrar Venta</button>
    </form>
    </div>
    {resultado_html}
    <script>
    const puntosVenta = {pv_json};

    function filtrarPuntosVenta() {{
      const idParque = parseInt(document.getElementById('idParque').value);
      const sel = document.getElementById('idPuntoVenta');
      sel.innerHTML = '<option value="">-- Seleccionar punto de venta --</option>';
      if (!idParque) return;
      const filtrados = puntosVenta.filter(pv => pv.idParque === idParque);
      filtrados.forEach(pv => {{
        const opt = document.createElement('option');
        opt.value = pv.id;
        opt.textContent = pv.desc;
        sel.appendChild(opt);
      }});
    }}
    </script>
    """
    return render_page(content)


# ============================================================
# RUTA: Baja — Listar y anular tickets
# ============================================================

@app.route("/tickets")
def listar_tickets():
    busqueda   = request.args.get("q", "").strip()
    id_parque  = request.args.get("idParque", "").strip()
    filtro_mes = request.args.get("mes", "").strip()
    filtro_dia = request.args.get("dia", "").strip()

    parques_filtro = consultar("""
        SELECT DISTINCT p.idParque, p.nombre
        FROM parques.Parque p
        JOIN parques.PuntoVenta pv ON pv.idParque = p.idParque
        JOIN ventas.Ticket t ON t.idPuntoVenta = pv.idPuntoVenta
        ORDER BY p.nombre
    """)

    # Construir WHERE dinámico
    where = []
    params = []

    if busqueda:
        where.append("(CAST(t.idTicket AS VARCHAR) = ? OR CAST(t.nroTicket AS VARCHAR) = ?)")
        params += [busqueda, busqueda]

    if id_parque:
        where.append("p.idParque = ?")
        params.append(int(id_parque))

    if filtro_dia:
        where.append("CAST(t.fechaEmision AS DATE) = ?")
        params.append(filtro_dia)
    elif filtro_mes:
        where.append("FORMAT(t.fechaEmision, 'yyyy-MM') = ?")
        params.append(filtro_mes)

    where_sql = "WHERE " + " AND ".join(where) if where else ""

    tickets = consultar(f"""
        SELECT TOP 50
            t.idTicket, t.nroTicket, t.fechaEmision,
            t.total, t.moneda, t.totalUSD,
            t.estado,
            p.nombre AS parque,
            pv.nombre AS puntoVenta,
            v.nombre + ' ' + v.apellido AS visitante,
            tv.nombre AS tipoVisitante
        FROM ventas.Ticket t
        JOIN parques.PuntoVenta pv ON pv.idPuntoVenta = t.idPuntoVenta
        JOIN parques.Parque p      ON p.idParque      = pv.idParque
        LEFT JOIN ventas.Entrada e  ON e.idItem IN (
            SELECT idItem FROM ventas.ItemTicket WHERE idTicket = t.idTicket
        )
        LEFT JOIN ventas.Visitante v   ON v.idVisitante     = e.idVisitante
        LEFT JOIN maestros.TipoVisitante tv ON tv.idTipoVisitante = v.idTipoVisitante
        {where_sql}
        ORDER BY t.fechaEmision DESC, t.idTicket DESC
    """, params if params else None)

    filas = ""
    for t in tickets:
        estado_badge = (
            f'<span class="badge-ok">Emitido</span>'
            if t["estado"] == "Emitido"
            else f'<span class="badge-err">Anulado</span>'
        )
        total = f"$ {t['total']:,.2f} ARS"
        if t["moneda"] == "USD" and t["totalUSD"]:
            total += f'<br><small style="color:#1a5c2a;font-weight:bold">USD {t["totalUSD"]:,.2f}</small>'

        visitante_str = t["visitante"] or "—"
        if t["tipoVisitante"]:
            visitante_str += f'<br><small style="color:#666">{t["tipoVisitante"]}</small>'

        nro = t["nroTicket"]
        anular_btn = (
            f'<a href="/tickets/anular/{t["idTicket"]}" class="btn btn-danger" '
            f'style="padding:4px 10px;font-size:12px" '
            f'onclick="return confirm(\'Anular ticket N° {nro}?\')">Anular</a>'
            if t["estado"] == "Emitido" else "—"
        )
        filas += f"""<tr>
          <td>{t['nroTicket']}</td>
          <td>{t['fechaEmision']}</td>
          <td>{t['parque']}<br><small style="color:#666">{t['puntoVenta']}</small></td>
          <td>{visitante_str}</td>
          <td>{total}</td>
          <td>{estado_badge}</td>
          <td>{anular_btn}</td>
        </tr>"""

    opts_parque = '<option value="">-- Todos los parques --</option>' + "".join(
        f'<option value="{p["idParque"]}" {"selected" if str(p["idParque"]) == id_parque else ""}>{p["nombre"]}</option>'
        for p in parques_filtro
    )

    from datetime import date as date_type
    hoy_str = date_type.today().isoformat()
    mes_str = date_type.today().strftime("%Y-%m")

    content = f"""
    <h2>&#128190; Tickets de Venta</h2>
    <div class="card" style="padding:14px 20px;margin-bottom:16px">
    <form method="GET" style="display:flex;gap:10px;flex-wrap:wrap;align-items:flex-end">
      <div>
        <label style="font-size:12px;font-weight:bold;display:block">Buscar por N° ticket</label>
        <input name="q" placeholder="N° o ID" value="{busqueda}" style="width:150px">
      </div>
      <div>
        <label style="font-size:12px;font-weight:bold;display:block">Parque</label>
        <select name="idParque" style="width:200px">{opts_parque}</select>
      </div>
      <div>
        <label style="font-size:12px;font-weight:bold;display:block">Filtrar por dia</label>
        <input type="date" name="dia" value="{filtro_dia}" style="width:160px">
      </div>
      <div>
        <label style="font-size:12px;font-weight:bold;display:block">Filtrar por mes</label>
        <input type="month" name="mes" value="{filtro_mes}" style="width:160px">
      </div>
      <div>
        <button type="submit" class="btn btn-info">Filtrar</button>
        <a href="/tickets" class="btn" style="background:#888;color:#fff">Limpiar</a>
      </div>
    </form>
    </div>
    <table>
      <thead><tr>
        <th>N° Ticket</th><th>Fecha</th><th>Parque / Punto de Venta</th>
        <th>Visitante</th><th>Total</th><th>Estado</th><th>Accion</th>
      </tr></thead>
      <tbody>{filas if filas else '<tr><td colspan="7" style="text-align:center;color:#888">Sin resultados</td></tr>'}</tbody>
    </table>
    <p style="font-size:12px;color:#888;margin-top:8px">Mostrando hasta 50 tickets.</p>
    """
    return render_page(content)


@app.route("/tickets/anular/<int:id_ticket>")
def anular_ticket(id_ticket):
    _, error = ejecutar_sp("sp_AnularTicket", {"idTicket": id_ticket})
    if error:
        flash(error, "danger")
    else:
        flash(f"Ticket #{id_ticket} anulado correctamente.", "success")
    return redirect(url_for("listar_tickets"))


# ============================================================
# MAIN
# ============================================================

if __name__ == "__main__":
    print("=" * 50)
    print("  Parques Nacionales - App Ventas")
    print("  Usuario: usr_ventas (rol_ventas)")
    print("  http://localhost:5000")
    print("=" * 50)
    app.run(debug=True, port=5000)