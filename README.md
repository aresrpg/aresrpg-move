<p align=center>
  <img src="https://user-images.githubusercontent.com/11330271/208825167-77d7bc78-17d0-4f33-ad35-d108b6fac730.gif" height="237px" width="344"/>
</p>
<h1 align=center>AresRPG</h1>
<p align=center>
  <img src="https://img.shields.io/badge/Made%20with-Javascript-%23f7df1e?style=for-the-badge" alt="fully in javascript"/>
  <img src="https://img.shields.io/badge/Powered%20By-Black%20Magic-blueviolet?style=for-the-badge" alt="powered by lsd"/>
  <a href="https://discord.gg/aresrpg">
    <img src="https://img.shields.io/discord/265104803531587584.svg?logo=discord&style=for-the-badge" alt="Chat"/>
  </a>
</p>
<h3 align=center>Move modules for AresRPG on Sui</h3>

AresRPG is a multiplayer voxel RPG which has no serverside database, everything
is stored on [Sui](https://sui.io/).

Here is a description of the flow used.

## Initialization

AresRPG is a single entity providing verification on the game, and allows players
to progress according to a set of private rules managed off-chain.

- The user must create its own objects with enforced default values
- The user then request a connector from the server module which will create a new shared object where the user can store and withdraw his data
- This connector allows the publisher of the server module to mutate any data stored inside, effectively allowing the server to act on the user state
- While the user state is in the connector, the server considers the player valid and will allow access to game servers

> The player can withdraw his state at anytime but will be disconnected from the server, this is unsafe if done while playing as the server isn't saving player's progress on each interraction but rather at specific batched intervals
