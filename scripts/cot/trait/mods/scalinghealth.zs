#loader contenttweaker
#modloaded scalinghealth ctintegration

import crafttweaker.player.IPlayer;
import mods.zenutils.NetworkHandler;
import crafttweaker.entity.IEntity;
import mods.contenttweaker.tconstruct.Trait;
import crafttweaker.item.IItemStack;
import mods.contenttweaker.conarm.ArmorTrait;

// /////////////////////////////////////////////////////////////////////////////
// /////////////////////////////////////////////////////////////////////////////
val a = mods.contenttweaker.tconstruct.TraitBuilder.create('challenger');
a.color = 0xD1310D;
a.maxLevel = 4;
a.localizedName = game.localize('e2ee.tconstruct.material.challenger.name');
a.localizedDescription = game.localize('e2ee.tconstruct.material.challenger.description');

a.getMiningSpeed = function(trait, tool, e) {
  e.newSpeed = e.originalSpeed * getToolBonus(trait, tool, e.player);
};

a.calcDamage = function(trait, tool, attacker, target, originalDamage, newDamage, isCritical) {
  return newDamage * getToolBonus(trait, tool, target);
};

a.afterHit = function(trait, tool, attacker, target, damageDealt, wasCritical, wasHit) {
	if (attacker.world.remote || !wasHit) return;
  showFX(attacker, target.x, target.y, target.z, damageDealt);
};

a.afterBlockBreak = function(trait, tool, world, blockstate, blockPos, miner, wasEffective) {
	if (miner.world.remote || !wasEffective) return;
  showFX(miner, 0.5 + blockPos.x, 0.5 + blockPos.y, 0.5 + blockPos.z, 1.0);
};
// a.extraInfo = function(trait, tool, tag) {
//   return [] as string[];
// };
a.register();

// /////////////////////////////////////////////////////////////////////////////
// /////////////////////////////////////////////////////////////////////////////
val b = mods.contenttweaker.conarm.ArmorTraitBuilder.create('challenger');
b.color = 0xD1310D;
b.localizedName = game.localize('e2ee.tconstruct.material.challenger.name');
b.localizedDescription = game.localize('e2ee.tconstruct.material.challenger.description');
b.maxLevel = 4;
b.getModifications = function(trait, player, mods, armor, damageSource, damage, index) {
  if (damage <= 0.0) return mods;
  val bonus = getArmorBonus(trait, armor, player);
  mods.armorMod *= bonus;
  mods.toughnessMod *= bonus;
  return mods;
};
b.onDamaged = function (trait, armor, player, source, damage, newDamage, evt) {
  if (player.world.remote || newDamage <= 0) return newDamage;
  val bonus = getArmorBonus(trait, armor, player);
  showFX(player, player.x, player.y, player.z, bonus);
  return newDamage;
};
b.register();

// /////////////////////////////////////////////////////////////////////////////
// /////////////////////////////////////////////////////////////////////////////
function showFX(entity as IEntity, x as double,y as double,z as double, value as double) as void {
  NetworkHandler.sendToAllAround('acquire_star_and_flare',
    entity.x, entity.y, entity.z, 30, entity.world.getDimension(), function(b){
    b.writeData({ x: x, y: y, z: z, value: value });
  });
}

function getToolBonus(trait as Trait, tool as IItemStack, entity as IEntity) as double {
  if (isNull(trait)) return 1.0;
  val data = trait.getData(tool);
  if (isNull(data)) return 1.0;
  return getAnyBonus(data.level, entity);
}

function getArmorBonus(trait as ArmorTrait, tool as IItemStack, entity as IEntity) as double {
  if (isNull(trait)) return 1.0;
  val data = trait.getData(tool);
  if (isNull(data)) return 1.0;
  return getAnyBonus(data.level, entity);
}

function getAnyBonus(level as double, entity as IEntity) as double {
  val areaDiff = entity.world.getAreaDifficultyAt(entity.position);
  return getBonus(areaDiff, level);
}

function getBonus(areaDiff as double, level as double) as double {
  return (areaDiff / 100.0 + 1.0) * level;
}
