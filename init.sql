CREATE TABLE IF NOT EXISTS `alumnos` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `nombre` VARCHAR(100) NOT NULL,
    `apellido` VARCHAR(100) NOT NULL,
    PRIMARY KEY (`id`)
);

INSERT INTO `alumnos` (`nombre`, `apellido`) VALUES
('Juan', 'Pérez'),
('María', 'González'),
('Carlos', 'Rodríguez');
