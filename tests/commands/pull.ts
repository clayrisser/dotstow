import Pull from '../../src/commands/pull';
import pull from '../../src/actions/pull';

jest.mock('../../src/actions/pull', () => jest.fn(() => 'PULL_RESPONSE'));

describe('pull command', () => {
  it('should call `pull` with default options', async () => {
    const result = await Pull.run([]);

    expect(pull).toHaveBeenCalledWith({ debug: false, branch: undefined });

    expect(result).toBe('PULL_RESPONSE');
  });

  it('should call `pull` with debug enabled', async () => {
    await Pull.run(['--debug']);

    expect(pull).toHaveBeenCalledWith({ debug: true, branch: undefined });
  });

  it('should call `pull` with passed branch', async () => {
    await Pull.run(['--branch=main']);

    expect(pull).toHaveBeenCalledWith({ debug: false, branch: 'main' });
  });
});
