function new_policy = klsq_spd(domain, samples, policy, new_policy, mu)

    exemplars = ald_analysis(samples, new_policy, mu);

    howmany    = length(samples);
    k          = size(exemplars,1);
    r_hat      = zeros(howmany, 1);
    k_hat      = zeros(howmany, k);
    k_hat_next = zeros(howmany, k);

    basis_function = new_policy.basis;
    param_function = [domain '_parameters'];

    parameters = feval(param_function);

    parfor i=1:howmany
        
        %because we're in a multi-thread environment we need to 
        %re-init our algorithm's parameters so we can use them here
        feval(param_function, parameters);

        k_hat(i,:) = feval(basis_function, samples(i).state, samples(i).action, exemplars);
        r_hat(i)   = samples(i).reward;

        if ~samples(i).absorb
            nextaction      = policy_function(policy, samples(i).nextstate);
            k_hat_next(i,:) = feval(basis_function, samples(i).nextstate, nextaction, exemplars);
        else
            k_hat_next(i,:) = zeros(1,k);
        end
    end

    A = k_hat' * (k_hat - new_policy.discount * k_hat_next);
    b = k_hat' * r_hat;

    if rank(A) == k
        w = A\b;
    else
        w = pinv(A)*b;
    end

    new_policy.weights   = w;
    new_policy.exemplars = exemplars;
    new_policy.explore   = 0;

    return
end