{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "joesite";

  packages = with pkgs; [
    elmPackages.elm
    nodejs_22
  ];
}
