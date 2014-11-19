package My::ModuleBuild;

use strict;
use warnings;
use base qw( Alien::Base::ModuleBuild );
use File::chdir;
use Capture::Tiny qw( capture_stderr );
use File::Spec;

our $quiet = 0;

my $patch = $^O eq 'MSWin32' ? 'patch --binary' : 'patch';

sub new
{
  my($class, %args) = @_;
  
  $args{alien_name} = 'bison';
  $args{alien_build_commands} = [
    "$patch -p1 < ../../bison-3_0_2.patch",
    '%c --prefix=%s',
    'make MANS=',
    'touch doc/bison.1 doc/yacc.1',
  ];
  $args{alien_install_commands} = [
    'make install',
  ];
  $args{alien_repository} = {
    protocol => 'http',
    host     => 'ftp.gnu.org',
    location => '/gnu/bison/',
    pattern  => qr{^bison-3\.0\.2\.tar\.gz$},
  };

  if($ENV{ALIEN_FORCE} || do { local $quiet = 1; $class->alien_check_installed_version })
  {
    $args{alien_bin_requires} = { 'Alien::m4' => 0, 'Alien::patch' => '0.03', };
  }
  
  my $self = $class->SUPER::new(%args);
  
  $self;
}

sub _short ($)
{
  $_[0] =~ /\s+/ ? Win32::GetShortPathName( $_[0] ) : $_[0];
}

sub alien_check_installed_version
{
  my($self) = @_;

  my @paths = ([]);

  if($^O eq 'MSWin32')
  {
    eval '# line '. __LINE__ . ' "' . __FILE__ . "\n" . q{
      use strict;
      use warnings;
      use Win32API::Registry 0.21 qw( :ALL );
      
      my @uninstall_key_names = qw(
        software\wow6432node\microsoft\windows\currentversion\uninstall
        software\microsoft\windows\currentversion\uninstall
      );
      
      foreach my $uninstall_key_name (@uninstall_key_names)
      {
        my $uninstall_key;
        RegOpenKeyEx( HKEY_LOCAL_MACHINE, $uninstall_key_name, 0, KEY_QUERY_VALUE | KEY_ENUMERATE_SUB_KEYS, $uninstall_key ) || next;
        
        my $pos = 0;
        my($subkey, $class, $time) = ('','','');
        my($namSiz, $clsSiz) = (1024,1024);
        while(RegEnumKeyEx( $uninstall_key, $pos++, $subkey, $namSiz, [], $class, $clsSiz, $time))
        {
          next unless $subkey =~ /^bison/i;
          my $bison_key;
          RegOpenKeyEx( $uninstall_key, $subkey, 0, KEY_QUERY_VALUE, $bison_key ) || next;
          
          my $data;
          if(RegQueryValueEx($bison_key, "InstallLocation", [], REG_SZ, $data, [] ))
          {
            push @paths, [File::Spec->catdir(_short $data, "bin")];
          }
          
          RegCloseKey( $bison_key );
        }
        RegCloseKey($uninstall_key);
      }
    };
    warn $@ if $@;
    
    push @paths, map { [_short $ENV{$_}, qw( GnuWin32 bin )] } grep { defined $ENV{$_} } qw[ ProgramFiles ProgramFiles(x86) ];
    push @paths, ['C:\\GnuWin32\\bin'];
    
  }
  
  unless($quiet)
  {
    print "try system paths:\n";
    print "  - ", $_, "\n" for map { $_ eq '' ? 'PATH' : $_ } map { File::Spec->catdir(@$_) } @paths;
  }
  
  foreach my $path (@paths)
  {
    my @stdout;
    my $exe = File::Spec->catfile(@$path, 'bison');
    my $stderr = capture_stderr {
      @stdout = `$exe --version`;
    };
    if(defined $stdout[0] && $stdout[0] =~ /^bison/ && $stdout[0] =~ /([0-9\.]+)$/)
    {
      $self->config_data( bison_system_path => File::Spec->catdir(@$path) ) if ref($self) && @$path;
      return $1;
    }
  }
  return;
}

sub alien_check_built_version
{
  $CWD[-1] =~ /^bison-(.*)$/ ? $1 : 'unknown';
}

1;
