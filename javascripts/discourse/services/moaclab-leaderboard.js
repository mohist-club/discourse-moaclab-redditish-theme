import Service, { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";

const CACHE_DURATION = 5 * 60 * 1000;

export default class MoaclabLeaderboard extends Service {
  @service currentUser;

  cache = new Map();

  load(id) {
    if (!Number.isInteger(id) || id < 1) {
      return Promise.resolve(null);
    }

    // Keep permission-sensitive results in memory, separated by account.
    const userId = this.currentUser?.id ?? null;
    const key = `${userId}:${id}`;
    const cached = this.cache.get(key);
    if (cached && (cached.pending || Date.now() < cached.expiresAt)) {
      return cached.promise;
    }

    const entry = { pending: true };
    entry.promise = ajax(`/leaderboard/${id}.json`)
      .then((result) => {
        if (
          (this.currentUser?.id ?? null) !== userId ||
          result?.leaderboard?.id !== id ||
          !Array.isArray(result.users)
        ) {
          return null;
        }

        return {
          id,
          name: result.leaderboard.name,
          users: result.users.filter(
            (user) =>
              typeof user.username === "string" &&
              user.username.length > 0 &&
              Number.isInteger(user.position) &&
              user.position > 0 &&
              Number.isFinite(user.total_score)
          ),
        };
      })
      .catch(() => null)
      .finally(() => {
        entry.pending = false;
        entry.expiresAt = Date.now() + CACHE_DURATION;
      });

    this.cache.set(key, entry);
    return entry.promise;
  }
}
