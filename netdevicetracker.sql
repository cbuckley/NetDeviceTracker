CREATE TABLE IF NOT EXISTS `devices` (
  `d_mac` varchar(20) NOT NULL,
  `d_ip` varchar(15) NOT NULL,
  `d_dns` text NOT NULL,
  `d_note` text NOT NULL,
  `d_alert` tinyint(1) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `log` (
  `l_mac` int(17) NOT NULL,
  `l_ip` varchar(15) NOT NULL,
  `l_dns` text NOT NULL,
  `l_datetime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=MyISAM DEFAULT CHARSET=latin1;


CREATE TABLE IF NOT EXISTS `variables` (
  `v_id` int(11) NOT NULL AUTO_INCREMENT,
  `v_name` varchar(56) NOT NULL,
  `v_value` varchar(56) NOT NULL,
  `v_area` varchar(56) NOT NULL,
  PRIMARY KEY (`v_id`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1 AUTO_INCREMENT=5 ;

INSERT INTO `variables` (`v_id`, `v_name`, `v_value`, `v_area`) VALUES
(1, 'password', 'YOURPASS', 'access telnet'),
(2, 'username', 'USER', 'telnet acces'),
(3, 'pushingbox_api', 'APIKEY', 'pushingbox api'),
(4, 'host', 'HOST', 'telnet');