package Alien::bison;

use strict;
use warnings;
use base qw( Alien::Base );

# ABSTRACT: Find or build bison, the parser generator
our $VERSION = '0.07'; # VERSION


sub bin_dir
{
  my($class) = @_;
  if($class->install_type('system'))
  {
    my $path = $class->config('bison_system_path');
    return ($path) if $path;
  }

  return $class->SUPER::bin_dir;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::bison - Find or build bison, the parser generator

=head1 VERSION

version 0.07

=head1 SYNOPSIS

From a Perl script

 use Alien::bison;
 use Env qw( @PATH );
 unshift @PATH, Alien::bison->bin_dir;  # bison is now in your path

From Alien::Base Build.PL

 use Alien:Base::ModuleBuild;
 my $builder = Module::Build->new(
   ...
   alien_bin_requires => [ 'Alien::bison' ],
   ...
 );
 $builder->create_build_script;

=head1 DESCRIPTION

This package can be used by other CPAN modules that require bison,
the GNU Parser generator based on YACC.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
