final: prev: {
  rosPackages = prev.rosPackages // {
    jazzy = prev.rosPackages.jazzy.overrideScope (
      rfinal: rprev: {
        hls-lfcd-lds-driver = rprev.hls-lfcd-lds-driver.overrideAttrs (old: {
          version = "${old.version}+patched";
          __intentionallyOverridingVersion = true;
          postPatch = (old.postPatch or "") + ''
            # Boost 1.89 dropped the empty boost_system stub library
            sed -i -E '/find_package\(Boost/ s/\bsystem\b//' CMakeLists.txt

            # Boost 1.87 removed the deprecated io_service alias
            grep -rlE 'io_service' src include 2>/dev/null \
              | xargs -r sed -i 's/boost::asio::io_service/boost::asio::io_context/g'
          '';
        });

        ld08-driver = rprev.ld08-driver.overrideAttrs (old: {
          version = "${old.version}+patched";
          src = final.fetchFromGitHub {
            owner = "ROBOTIS-GIT";
            repo = "ld08_driver";
            rev = "jazzy";
            hash = "sha256-C+gZEw2ZbEV31Zvt/zo3/MTKJo0jmWKqk0pfcGx1aT4=";
          };
          # Ubuntu 24.04 uses glibc 2.39, but nixpkgs uses glibc 2.42
          # cfsetispeed() only sets ispeed 115200, leaving ospeed at 9600
          # Replacing with cfsetspeed sets both ispeed and ospeed to 15200
          postPatch = (old.postPatch or "") + ''
            sed -i 's/cfsetispeed(&options, \(B[0-9]*\))/cfsetspeed(\&options, \1)/' src/cmd_interface_linux.cpp
          '';
        });
      }
    );
  };
}
