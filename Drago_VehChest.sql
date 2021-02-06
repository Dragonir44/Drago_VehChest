CREATE TABLE `VehChest`(
    `id` int(11) NOT NULL,
    `label` varchar(100) NOT NULL,
    `item` varchar(100) NOT NULL,
    `type` varchar(100) NOT NULL,
    `count` int(11) NOT NULL,
    `plate` varchar(8) NOT NULL,
    `owned` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

ALTER TABLE `VehChest`
 ADD PRIMARY KEY (`id`);

ALTER TABLE `VehChest`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `VehChest` ADD UNIQUE( `item`, `plate`);