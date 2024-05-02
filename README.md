<p align=center>
  <img src="https://user-images.githubusercontent.com/11330271/208825167-77d7bc78-17d0-4f33-ad35-d108b6fac730.gif" height="237px" width="344"/>
</p>
<h1 align=center>AresRPG</h1>
<p align=center>
  <img src="https://img.shields.io/badge/Made%20with-Move-blue?style=for-the-badge" alt="fully in Move"/>
  <img src="https://img.shields.io/badge/Powered%20By-Dark%20Magic-blueviolet?style=for-the-badge" alt="powered by lsd"/>
  <a href="https://discord.gg/aresrpg">
    <img src="https://img.shields.io/discord/265104803531587584.svg?logo=discord&style=for-the-badge" alt="Chat"/>
  </a>
</p>
<h3 align=center>Move modules for AresRPG on Sui</h3>

AresRPG is a multiplayer voxel RPG which has no serverside database, everything
is stored on [Sui](https://sui.io/).

## Publish a package

- change the `rev` version in `Move.toml` to correspond to the wanted network
- `npm run publish::<network>`
- update `publish-at` in `Move.toml`
- update env in `aresrpg-sdk`

## Upgrade a package

- make sure the `rev` version in `Move.toml` is correct
- update the PACKAGE_VERSION in `aresrpg-move/sources/version.move`
- `npm run upgrade::<network>`
- update env in `aresrpg-sdk`