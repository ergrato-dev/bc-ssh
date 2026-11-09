-- Base de datos de ejemplo del laboratorio (semana 08): db la carga la
-- primera vez que arranca con el volumen vacío.
CREATE TABLE productos (
    id      serial PRIMARY KEY,
    nombre  text NOT NULL,
    precio  numeric(8,2) NOT NULL
);

INSERT INTO productos (nombre, precio) VALUES
    ('teclado', 45.00),
    ('ratón', 19.90),
    ('monitor', 189.00);
