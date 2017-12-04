#
# send2ls.pl (send to logstash)
# Objetivo : Envia entrada al logstash
# Parametro: 
#       $texto: Texto del registro a enviar a Logstash
#

use strict;
use warnings;
use Config::Tiny;
use IO::Socket::INET;
use Socket;
use Sys::Hostname;

my $host = hostname();
my $addr = inet_ntoa(scalar(gethostbyname($host)) || 'localhost');

$| = 1;  # auto-flush (para el socket)
my $DEBUG=1;

# lee configuracion
my $Config = Config::Tiny->new;
$Config = Config::Tiny->read( 'send2ls.conf' );
my $HOSTS   = $Config->{logstash}->{hosts};
my $STDPORT = $Config->{logstash}->{port};

die "$0\nError: $Config::Tiny::errstr" if $Config::Tiny::errstr;

my $texto   = shift; 
die "Error:\n\tUso: $0 \"texto a enviar\"" if ( ! $texto );

# crea el socket
my $socket ;
$socket = new IO::Socket::INET (
    PeerHost  => $HOSTS,
    PeerPort  => $STDPORT, 
    Proto     => 'tcp',
    Blocking  => 0,
    Timeout   => 3,
    Type      => SOCK_STREAM,
) or die "no pude conectarme al servidor $HOSTS $STDPORT\n$!\n" unless $socket;

print "conectado a logstash  $HOSTS $STDPORT\n";

# envia msg al server
 
my $ts=localtime();
$texto =~ s/,/\,/g;  # dado que el texto es CSV
my $msg = "$ts,$host,$texto";
my $size = $socket->send($msg."\n");
print "msg enviado: $msg\n";
print "largo msg enviado: $size\n";

# notifica al server que el requerimiento fue enviado  
shutdown($socket, 1);

#print "esperando respuesta ...\n" if $DEBUG;
my $SEG=1;
sleep($SEG);

# respuesta desde el server ...  hasta 1024 caracteres
my $response = "";
$socket->recv($response, 1024);
print "respuesta recibida desde el server: $response\n" if $response;
 
$socket->close();

