<?php
header("Content-Type: text/json; charset=UTF-8");

$service_port = 15535;
$address = ('localhost');
$socket = stream_socket_client('tcp://'.$address.':'.$service_port);

switch($_SERVER['PATH_INFO']){
  case ('/v1/version'):
    fwrite($socket, "version\n");
    break;
  case ('/v1/systems'):
    fwrite($socket, "systems\n");
    break;
  case ('/v1/systeminfo'):
    fwrite($socket, "systeminfo\n");
    fwrite($socket, $_GET['system']."\n");
    break;
  case ('/v1/diceroll'):
    fwrite($socket, "diceroll\n");
    fwrite($socket, $_GET['system']."\n");
    fwrite($socket, $_GET['command']."\n");
    break;
  default:
    fwrite($socket, "HELO\n");
}

while($str = fgets($socket)){
  echo $str;
}

fclose($socket);
?>